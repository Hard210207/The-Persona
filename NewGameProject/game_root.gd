extends Control

# --- Game Variables ---
var secret_identity = ""
var passenger_type = "" # Stores "Human", "Entity", or "Animal"
var questions_asked_count = 0
var max_questions = 3
var distinct_questions_asked = []

# --- New Lives Logic ---
var max_lives = 3
var current_lives = 3

# --- Data ---
var character_data = {
	"Ghost": {
		"type": "Entity",
		"answers": [
			"I... I just like to walk the same streets. It helps me remember.",
			"It felt like a dream. I blinked, and the sun was gone.",
			"Technically, yes. But my house is always full of people. They just... don't see me.",
			"I’ve been here longer than these buildings. I think I belong to this town now.",
			"I used to make people laugh. Now? I just... watch them cry.",
			"I remember the taste of apples. But I haven't been hungry in... a very long time."
		]
	},
	"Cat": {
		"type": "Animal",
		"answers": [
			"The night belongs to me. Too much noise during the day. Too many... feet.",
			"Acceptable. I found a sunbeam and stayed there for six hours.",
			"I have a roommate. He is useless, but he opens the cans for me.",
			"This is MY territory. You are the one just passing through.",
			"I specialize in... pest control. And judgment.",
			"Fish. Fresh. With the head still on. I like the crunch."
		]
	},
	"Fox": {
		"type": "Animal",
		"answers": [
			"Just prowling. The city gets quiet now. Easier to find snacks.",
			"Slept under a porch. Chased a squirrel. It was a good day.",
			"I have a pack, but I hunt alone. Less sharing that way.",
			"I lived in these woods before they poured the concrete.",
			"I'm a survivor. And I'm very good at hiding in plain sight.",
			"Berries, beetles, or whatever you have in that bag. I'm not picky."
		]
	},
	"Human": {
		"type": "Human",
		"answers": [
			"Just got off a double shift. My feet are killing me, man.",
			"Stressful. My boss is a nightmare. I just want a beer.",
			"I wish. My wife is waiting up for me, probably mad I'm late.",
			"Born and raised here. Unfortunately. Can't afford to move.",
			"I work in billing. It's as boring as it sounds.",
			"Honestly? I'd kill for a greasy cheeseburger right now."
		]
	},
	"Monster": {
		"type": "Entity",
		"answers": [
			"Just finished a... heavy dinner. You're lucky I'm full.",
			"Delicious. The city has such a unique... flavor when you know where to look.",
			"I invite people over for dinner often. But they never seem to leave.",
			"I'm just visiting your world. I heard the... local cuisine... was excellent.",
			"I help with... population control.",
			"I prefer my steak rare. Very rare. Still screaming, if possible."
		]
	}
}

var questions_list = [
	"What are you doing here at this time?",
	"How was your day today?",
	"Do you live alone?",
	"Are you a tourist?",
	"What do you do?",
	"What do you like to eat?"
]

# --- Onready Nodes ---
@onready var display_text = $Answer_Display
@onready var status_label = $Ques_used
@onready var question_container = $Panel/QuestionContainer
@onready var guess_container = $GuessContainer

func _ready():
	# Initialize lives only once when the game first loads
	current_lives = max_lives
	start_new_round()

func start_new_round():
	# Reset round-specific variables
	questions_asked_count = 0
	distinct_questions_asked.clear()
	
	# Pick a Random Passenger
	var keys = character_data.keys()
	secret_identity = keys[randi() % keys.size()]
	passenger_type = character_data[secret_identity]["type"]
	
	# Optional: Keep questions in order (uncomment below line to shuffle)
	# questions_list.shuffle()
	
	print("DEBUG: Secret Identity: " + secret_identity + " | Type: " + passenger_type)
	
	# UI Reset
	display_text.text = "A new passenger enters..."
	display_text.modulate = Color.WHITE
	update_status_label()
	
	question_container.show()
	guess_container.hide()
	
	setup_buttons()

func setup_buttons():
	var q_buttons = question_container.get_children()
	for i in range(q_buttons.size()):
		var btn = q_buttons[i]
		if i < questions_list.size():
			btn.text = questions_list[i]
			btn.show()
		else:
			btn.hide()
		
		# Disconnect old signals so we don't click twice
		if btn.is_connected("pressed", self._on_question_pressed):
			btn.disconnect("pressed", self._on_question_pressed)
		# Connect new signal
		btn.pressed.connect(self._on_question_pressed.bind(i))
	
	# Setup Guess Buttons (Ensure buttons are named "Human", "Entity", "Animal")
	for btn in guess_container.get_children():
		if btn.is_connected("pressed", self._on_guess_pressed):
			btn.disconnect("pressed", self._on_guess_pressed)
		btn.pressed.connect(self._on_guess_pressed.bind(btn.name))

func _on_question_pressed(question_index):
	if question_index in distinct_questions_asked:
		display_text.text = "You already asked that! Try another."
		return

	questions_asked_count += 1
	distinct_questions_asked.append(question_index)
	update_status_label()
	
	# Show Answer
	var answer = character_data[secret_identity]["answers"][question_index]
	display_text.text = answer
	
	# Check if out of questions
	if questions_asked_count >= max_questions:
		question_container.hide()
		await get_tree().create_timer(2.0).timeout
		trigger_guessing_phase()

func trigger_guessing_phase():
	guess_container.show()
	display_text.text = "That's enough questions. Who am I?"

func _on_guess_pressed(button_name):
	guess_container.hide()
	
	if button_name == passenger_type:
		# CORRECT GUESS
		display_text.text = "Correct! I was a " + secret_identity + ". You survived."
		display_text.modulate = Color.GREEN
		# Lives stay the same
	else:
		# WRONG GUESS
		current_lives -= 1
		display_text.text = "Wrong! I was a " + secret_identity + ". You lost a life."
		display_text.modulate = Color.RED
	
	update_status_label()
	
	# Wait 3 seconds, then decide what to do
	await get_tree().create_timer(3.0).timeout
	
	if current_lives <= 0:
		game_over()
	else:
		start_new_round()

func game_over():
	display_text.text = "GAME OVER. You ran out of lives."
	display_text.modulate = Color.RED
	
	# Wait 4 seconds then fully restart
	await get_tree().create_timer(4.0).timeout
	current_lives = max_lives # Reset Lives
	start_new_round()

func update_status_label():
	# Display Questions AND Lives
	status_label.text = "Questions: " + str(questions_asked_count) + "/" + str(max_questions) + " | Lives: " + str(current_lives)
