using Godot;
using System;
using System.Text.RegularExpressions;
using System.Collections.Generic;
public partial class SpeechUIManager : Node
{

	[Export] SpeechRecognizer speechRecognizer;

	private string partialResult;
	private string finalResult;
	

	public override void _Ready()
	{		
			SetProcess(this.GetMultiplayerAuthority() == Multiplayer.GetUniqueId());

		
			if (!speechRecognizer.isCurrentlyListening())
			{
				
				//OnStartSpeechRecognition();
				speechRecognizer.StartSpeechRecognition();
			}
			else
			{
				//OnStopSpeechRecognition();
				(string finalResult, Godot.Collections.Array<int> freq) = speechRecognizer.StopSpeechRecoginition();
			}
			
		speechRecognizer.OnPartialResult += (partialResult, freq) =>
		{
			GD.Print("Partial Freq ", freq);
			GD.Print("Partial Word ", partialResult);

		};
		
		speechRecognizer.OnFinalResult += (finalResult, freq) =>
		{
			MatchCollection mc = Regex.Matches(finalResult, @"h[a(ey?)(oe?)]");
			GD.Print("Freq ", freq);
			var laughModel = new Godot.Collections.Array<int>{12, 0, 5, 16, 0, 2};
			var comparisonSum = 0;
			for(int i = 0; i < 4; i++){
				comparisonSum += Math.Abs(laughModel[i] - freq[i]);
			}
			
			GD.Print("Compare ", comparisonSum);
			GD.Print("Compare Avg", comparisonSum / 4);

			
			if (mc.Count >= 3) {
				finalResult = "live";
			}
			else {
				finalResult = "die";
			}
			GD.Print(finalResult);
			//OnStopSpeechRecognition();
		};
	}

	public override void _Process(double delta)
	{
	}

	//private void OnStopSpeechRecognition()
	//{
		////startButton.Text = "Start Recognition";
		////startButton.Modulate = new Color(1, 1, 1, 1f);
	//}
//
//
	//private void OnStartSpeechRecognition()
	//{
		//startButton.Text = "Stop Recognition";
		//startButton.Modulate = new Color(1f, 0.5f, 0.5f, 1f);
	//}
}
