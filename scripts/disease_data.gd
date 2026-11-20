class_name DiseaseData
extends RefCounted

static func get_disease(id: String) -> Dictionary:
	match id:
		"stonebelly":
			return {
				"id": "stonebelly",
				"display_name": "Stonebelly",
				"remedy": "bellyease_draught",
				"complaint_text": "My stomach is swollen and tight...\nI haven't been able to go to the toilet in days.",
				"complaint_audio": "",
				"answers_pool": {
					"when_begin":       ["A week ago."],
					"sleep":            ["Very good, as usual.", "Can't sleep at all."],
					"appetite":         ["A few mouthfuls leave me feeling stuffed."],
					"stomach":          ["It's swollen and tight. I rarely go to the toilet."],
					"breathing":        ["Very good, as usual."],
					"worst_when":       ["After eating."],
					"brings_on":        ["Eating."],
					"getting_worse":    ["No.", "A little worse each morning."],
					"others_ill":       ["No."],
					"spots_sores":      ["No."],
					"sleep_elsewhere":  ["No.", "Slept somewhere else and felt the same."],
					"home_changes":     ["No.", "Got a new pet.", "The roof began leaking recently."],
					"bitten":           ["No.", "Tick.", "Rat.", "Dog."],
					"unusual_handling": ["No.", "Damp grain.", "Dead animals.", "Copper."],
					"bed_stain":        ["No."],
				}
			}
	return {}
