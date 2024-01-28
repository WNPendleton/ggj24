using Godot;
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using Vosk;
using Godot.Collections;
using System.Collections.Generic;



public partial class SpeechRecognizer : Node
{

	[Export(PropertyHint.Dir, "The VOSK model folder")]
	string modelPath = "res://model/en_us_small";
	[Export(PropertyHint.None, "The name of the bus that contains the record effect")]
	string recordBusName = "Record";
	[Export(PropertyHint.None, "Stop recognition after x milliseconds")]
	long timeoutInMS = 10000;
	[Export(PropertyHint.None, "Stop recognition if there is no change in output for x milliseconds.")]
	long noChangeTimeoutInMS = 3000;
	[Export(PropertyHint.None, "Don't stop recongizer until timeout.")]
	bool continuousRecognition = false;
	[Signal]
	public delegate void OnPartialResultEventHandler(string partialResults);
	[Signal]
	public delegate void OnFinalResultEventHandler(string finalResults, Godot.Collections.Array<double> freq);
	private int recordBusIdx;
	private AudioEffectRecord _microphoneRecord;  // The microphone recording bus effect
	private AudioEffectSpectrumAnalyzerInstance _spectrum;  // The microphone recording bus effect
	private bool isListening = false;
	private Model model;
	private string partialResult;
	private string finalResult;
	private Godot.Collections.Array<double> finalFreqResult;
	private ulong recordTimeStart;
	private ulong noChangeTimeOutStart;
	private CancellationTokenSource cancelToken;
	private double processInterval = 0.2;
	const int VU_COUNT = 16;
	private float FREQ_MAX = 11050.0F;

	private int WIDTH = 400;
	private int HEIGHT = 100;

	private float MIN_DB = 60F;
	
	private bool stereo = true;
	private int mix_rate = 44100;
	private int format = 1;

	public override void _Ready()
	{
		IntializeOSSpecificLibs(); //Doesn't seem to automatically load these libs
		recordBusIdx = AudioServer.GetBusIndex(recordBusName);

		_microphoneRecord = AudioServer.GetBusEffect(recordBusIdx, 0) as AudioEffectRecord;
		_spectrum = AudioServer.GetBusEffectInstance(recordBusIdx, 1) as AudioEffectSpectrumAnalyzerInstance;
		model = new Model(ProjectSettings.GlobalizePath(modelPath));
		Vosk.Vosk.SetLogLevel(0);
		cancelToken = new CancellationTokenSource();
		DebugPrint("Initialized Speech Recognition");
	}

	private static void IntializeOSSpecificLibs()
	{
		switch (OS.GetName())
		{
			case "Windows":
			case "UWP":
				NativeLibrary.Load(Path.Join(AppContext.BaseDirectory, "libvosk.dll"));
				break;
			case "macOS":
				NativeLibrary.Load(Path.Join(AppContext.BaseDirectory, "libvosk.dylib"));
				break;
			case "Linux":
			case "FreeBSD":
			case "NetBSD":
			case "OpenBSD":
			case "BSD":
				NativeLibrary.Load(Path.Join(AppContext.BaseDirectory, "libvosk.so"));
				break;
			case "Android":
				NativeLibrary.Load(Path.Join(AppContext.BaseDirectory, "libvosk.so"));
				break;
			case "iOS":
				GD.PrintErr("No IOS Support");
				break;
			case "Web":
				GD.PrintErr("No Web Support");
				break;
		}
	}

	private static void DebugPrint(string debugString)
	{
		if (OS.IsDebugBuild())
		{
			GD.Print(debugString);
		}
	}

	private void StartContinuousSpeechRecognition()
	{
		_ = Task.Factory.StartNew(async () =>
		{
			while (!cancelToken.IsCancellationRequested)
			{
				await Task.Delay(TimeSpan.FromSeconds(processInterval).Milliseconds, cancelToken.Token);
				ProcessMicrophone();
				ulong currentTime = Time.GetTicksMsec();
				if (!continuousRecognition && isListening && (currentTime - noChangeTimeOutStart) > (ulong)noChangeTimeoutInMS)
				{
					StopSpeechRecoginition();
				}
				else if (isListening && (currentTime - recordTimeStart) >= (ulong)timeoutInMS)
				{
					DebugPrint("Stopping from Timeout");
					StopSpeechRecoginition();
				}
			}
		});
	}

	private void ProcessMicrophone()
	{
		if (_microphoneRecord != null && _microphoneRecord.IsRecordingActive())
		{
			var recordedSample = _microphoneRecord.GetRecording();
			if (recordedSample != null)
			{
				recordedSample.Stereo = stereo;
				recordedSample.MixRate = mix_rate;

				VoskRecognizer recognizer = new(model, recordedSample.MixRate);
				byte[] data = recordedSample.Stereo ? MixStereoToMono(recordedSample.Data) : recordedSample.Data;
				var w = WIDTH / VU_COUNT;
			float prev_hz = 0F;
			//var freq = new Godot.Collections.Array{};
			//for(int i = 0; i < VU_COUNT+1; i++){
				var hz = FREQ_MAX / VU_COUNT;
				var magnitude = _spectrum.GetMagnitudeForFrequencyRange(prev_hz, hz).Length();
				var energy = Math.Clamp((MIN_DB + Mathf.LinearToDb(magnitude)) / MIN_DB, 0, 1);
				var height = energy * HEIGHT;
				//DrawRect(new Rect2(w * i, HEIGHT - height, w, height), Colors.White);

				
				prev_hz = hz;
				//}
			finalFreqResult.Add(height);
			GD.Print(finalFreqResult);

				if (!recognizer.AcceptWaveform(data, data.Length))
				{
					string currentPartialResult = recognizer.PartialResult();
					if (partialResult == null || !currentPartialResult.Equals(partialResult))
					{
						partialResult = currentPartialResult;
						noChangeTimeOutStart = Time.GetTicksMsec();
						CallDeferred("emit_signal", "OnPartialResult", partialResult);
					}
					EndRecognition(recognizer, finalFreqResult);
				}
				else if (!continuousRecognition) // Completed recognition
				{
					EndRecognition(recognizer, finalFreqResult);
					StopSpeechRecoginition();
				}
			}

		}
	}
	
	

	private void EndRecognition(VoskRecognizer recognizer,Godot.Collections.Array<double> freq)
	{
		finalResult = recognizer.FinalResult();
		finalFreqResult = freq;
		recognizer.Dispose(); //cleanup
	}

	public void StartSpeechRecognition()
	{
		if (cancelToken != null && !cancelToken.IsCancellationRequested)
		{
			cancelToken.Cancel();
		}
		cancelToken = new CancellationTokenSource();
		partialResult = "";
		finalResult = "";
		finalFreqResult = new Godot.Collections.Array<double>{};
		recordTimeStart = Time.GetTicksMsec();
		noChangeTimeOutStart = Time.GetTicksMsec();
		isListening = true;
		if (!_microphoneRecord.IsRecordingActive())
		{
			_microphoneRecord.SetRecordingActive(true);
		}
		StartContinuousSpeechRecognition();
	}

	public (string, Godot.Collections.Array<double>) StopSpeechRecoginition()
	{
		isListening = false;
		cancelToken.Cancel();
		if (_microphoneRecord.IsRecordingActive())
		{
			_microphoneRecord.SetRecordingActive(false);
			CallDeferred("emit_signal", "OnFinalResult", finalResult, finalFreqResult);
		}
		return (finalResult, finalFreqResult);
	}

	private byte[] MixStereoToMono(byte[] input)
	{
		// If the sample length can be divided by 4, it's a valid stero sound
		if (input.Length % 4 == 0)
		{
			byte[] output = new byte[input.Length / 2];                 // create a new byte array half the size of the stereo length
			int outputIndex = 0;
			for (int n = 0; n < input.Length; n += 4)                     // Loop through each stero sample
			{
				int leftChannel = BitConverter.ToInt16(input, n);        // Get the left channel
				int rightChannel = BitConverter.ToInt16(input, n + 2);     // Get the right channel
				int mixed = (leftChannel + rightChannel) / 2;           // Mix them together
				byte[] outSample = BitConverter.GetBytes((short)mixed); // Convert mix to bytes

				// copy in the first 16 bit sample
				output[outputIndex++] = outSample[0];
				output[outputIndex++] = outSample[1];
			}
			return output;
		}
		else
		{
			byte[] output = new byte[24];

			return output;
		}
	}
	public override void _Notification(int what)
	{
		if (what == NotificationWMCloseRequest)
		{
			model.Dispose();
			GetTree().Quit(); // default behavior
		}

	}

	public bool isCurrentlyListening()
	{
		return isListening;
	}
}

