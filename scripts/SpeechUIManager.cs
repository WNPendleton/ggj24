using Godot;
using System;
using System.Text.RegularExpressions;
using System.Collections.Generic;
public partial class SpeechUIManager : Node
{
	[Export] Button startButton;
	[Export] Label partialResultText;
	[Export] Label finalResultText;
	[Export] SpeechRecognizer speechRecognizer;

	private string partialResult;
	private string finalResult;
	

	public override void _Ready()
	{
		startButton.Pressed += () =>
		{
			if (!speechRecognizer.isCurrentlyListening())
			{
				partialResultText.Text = "";
				finalResultText.Text = "";
				OnStartSpeechRecognition();
				speechRecognizer.StartSpeechRecognition();
			}
			else
			{
				OnStopSpeechRecognition();
				(string finalResult, Godot.Collections.Array<double> freq) = speechRecognizer.StopSpeechRecoginition();
			}
		};
		speechRecognizer.OnPartialResult += (partialResult) =>
		{
			partialResultText.Text = partialResult;
		};
		
		speechRecognizer.OnFinalResult += (finalResult, freq) =>
		{
			MatchCollection mc = Regex.Matches(finalResult, @"h[a(ey?)(oe?)]");
			GD.Print("Freq ", freq);
			var laughModel = new Godot.Collections.Array<double>{2.95042037963867, 0, 34.6490516662598, 50.354248046875, 10.9075927734375};
			var testFreq = new Godot.Collections.Array<double>{};
			var comparisonSum = 0;
			for(int i = 0; i < 5; i++){
				comparisonSum += ((int)laughModel[i] - (int)freq[i]);
			}
			
			GD.Print("Compare ", comparisonSum);
			
			
			if (mc.Count >= 3) {
				finalResult = "live";
			}
			else {
				finalResult = "die";
			}
			finalResultText.Text = finalResult;
			OnStopSpeechRecognition();
		};
	}

	public override void _Process(double delta)
	{
	}

	private void OnStopSpeechRecognition()
	{
		startButton.Text = "Start Recognition";
		startButton.Modulate = new Color(1, 1, 1, 1f);
	}


	private void OnStartSpeechRecognition()
	{
		startButton.Text = "Stop Recognition";
		startButton.Modulate = new Color(1f, 0.5f, 0.5f, 1f);
	}
}
