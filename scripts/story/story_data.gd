# All story text lives here so it can be edited without touching game code.
# Story pages: "image" is optional; a missing file falls back to the game icon.
# Monk lines: plain strings shown in the bottom dialogue box.
class_name StoryData
extends RefCounted

const STORY_IMAGE_DIR := "res://assets/story/"

const INTRO := [
	{"image": "intro_1.png", "text": "Thuở xa xưa, thế giới được giữ cân bằng bởi năm Viên Đá Năng Lượng: Nước, Đất, Ánh Sáng, Gió và Sự Sống."},
	{"image": "intro_2.png", "text": "Rồi một ngày, ánh sáng của các viên đá lụi tắt. Năng lượng thoát ra, ngấm vào sinh vật của năm vùng đất và biến chúng thành quái thú."},
	{"image": "intro_3.png", "text": "Năm kẻ mạnh nhất đã nuốt trọn phần lớn sức mạnh ấy và trở thành chúa tể canh giữ vùng đất của mình."},
	{"image": "intro_4.png", "text": "Ngươi là người bảo hộ cuối cùng. Hãy thu hồi năng lượng, đánh bại các chúa tể và đánh thức năm viên đá."},
	{"image": "intro_5.png", "text": "Hành trình bắt đầu tại Đảo Hồi Sinh, nơi Monk vẫn đang chờ ngươi."},
]

const ENDING := [
	{"image": "ending_1.png", "text": "Viên đá cuối cùng bừng sáng. Năm luồng năng lượng hoà làm một, lan khắp các vùng đất."},
	{"image": "ending_2.png", "text": "Quái thú dần trở lại hình dáng hiền hoà vốn có. Biển xanh trở lại, rừng lại đâm chồi."},
	{"image": "ending_3.png", "text": "Monk cúi đầu: \"Thế giới nợ ngươi một lời cảm ơn, người bảo hộ.\""},
	{"image": "ending_4.png", "text": "Năm viên đá sẽ còn sáng mãi, chừng nào còn người canh giữ chúng."},
]

const MONK_WELCOME := [
	"Ngươi tới rồi. Năm viên đá quanh ta đều đã tắt lịm.",
	"Hãy bắt đầu từ Vùng Nước. Water guardian đang cần giúp đỡ, hãy tới gặp hắn trước.",
	"Hạ quái, thu Energy, đánh bại chúa tể rồi mang Energy về đây. Ta sẽ giúp ngươi đánh thức viên đá.",
]

# Shown by Monk right after a stone's celebration overlay.
const MONK_STONE_ACTIVATED := {
	&"water": [
		"Đá Nước đã thức tỉnh! Ta trao cho ngươi sức mạnh Hồi Phục. Nhấn nút Heal khi máu thấp.",
		"Cổng tới Vùng Đất đã mở. Hãy tìm Earth guardian.",
	],
	&"earth": [
		"Đá Đất đã thức tỉnh! Ngươi đã có Quyền Trượng. Dùng nút đổi vũ khí để tấn công từ xa.",
		"Cổng tới Vùng Ánh Sáng đã mở. Hãy tìm Light guardian.",
	],
	&"light": [
		"Đá Ánh Sáng đã thức tỉnh! Ngươi đã học được Tấn Công Diện Rộng, một quả cầu tự tìm tới kẻ địch gần nhất.",
		"Cổng tới Vùng Gió đã mở. Hãy tìm Air guardian.",
	],
	&"air": [
		"Đá Gió đã thức tỉnh! Từ giờ ngươi có thể chạm vào từng viên đá để dùng Energy nâng chỉ số.",
		"Cổng tới Vùng Sự Sống đã mở. Hãy tìm Life guardian. Đó là thử thách cuối cùng.",
	],
}

# Region banner shown every time the player enters a region.
const REGION_QUESTS := {
	&"water": {"title": "VÙNG NƯỚC", "quest": "Tiêu diệt Bomb Fish, Paddle Shark · Đánh bại Rùa Khổng Lồ"},
	&"earth": {"title": "VÙNG ĐẤT", "quest": "Tiêu diệt Nhện, Rắn · Đánh bại Gấu Trúc"},
	&"light": {"title": "VÙNG ÁNH SÁNG", "quest": "Tiêu diệt Hex Shaman, Torch Goblin · Đánh bại Minotaur"},
	&"air": {"title": "VÙNG GIÓ", "quest": "Tiêu diệt Imp, Ong · Đánh bại Dơi Khổng Lồ"},
	&"life": {"title": "VÙNG SỰ SỐNG", "quest": "Tiêu diệt Thief, Spear Goblin · Đánh bại Troll"},
}

# Victory dialog text after each region's boss is defeated.
const REGION_VICTORY := {
	&"water": "Rùa Khổng Lồ đã gục ngã! Năng lượng của Đá Nước đã về tay ngươi. Hãy trở về Đảo Hồi Sinh và trao Energy cho Monk.",
	&"earth": "Gấu Trúc đã gục ngã! Năng lượng của Đá Đất đã về tay ngươi. Hãy trở về Đảo Hồi Sinh và trao Energy cho Monk.",
	&"light": "Minotaur đã gục ngã! Năng lượng của Đá Ánh Sáng đã về tay ngươi. Hãy trở về Đảo Hồi Sinh và trao Energy cho Monk.",
	&"air": "Dơi Khổng Lồ đã gục ngã! Năng lượng của Đá Gió đã về tay ngươi. Hãy trở về Đảo Hồi Sinh và trao Energy cho Monk.",
	&"life": "Troll, chúa tể cuối cùng, đã gục ngã! Hãy mang Energy về cho Monk để đánh thức viên đá cuối cùng.",
}

# Lancer quests: each guardian opens its gate only after its quest is done.
# "goal" is how many steps finish the quest; "hud" is the HUD tracker text.
const LANCER_QUESTS := {
	&"water": {
		"guardian": "Water guardian",
		"goal": 1,
		"hud": "Tìm thảo dược phát sáng: %d/%d",
		"offer": [
			"Dừng lại, người bảo hộ! Ta bị thương khi chặn lũ quái tràn lên từ Vùng Nước.",
			"Trên đảo có một loại thảo dược phát sáng mọc lẫn giữa các bụi cỏ. Tìm giúp ta một cây, ta sẽ mở cổng cho ngươi.",
		],
		"reminder": ["Thảo dược mọc lẫn giữa các bụi cỏ. Hãy để ý ánh sáng xanh lấp lánh."],
		"complete": [
			"Đúng là nó rồi! Vết thương của ta đã đỡ hơn nhiều.",
			"Cổng tới Vùng Nước đã sẵn sàng. Cẩn thận lũ Bomb Fish!",
		],
	},
	&"earth": {
		"guardian": "Earth guardian",
		"goal": 3,
		"hud": "Tìm quặng cổ: %d/%d",
		"offer": [
			"Ngọn giáo của ta đã gãy trong trận chiến với lũ Nhện.",
			"Quanh đảo có những mảnh quặng cổ phát ánh cam. Mang cho ta 3 mảnh để rèn lại giáo.",
		],
		"reminder": ["Ta vẫn cần đủ 3 mảnh quặng cổ. Hãy tìm những hòn đá phát ánh cam."],
		"complete": [
			"Quặng tốt lắm! Ngọn giáo này sẽ giữ cổng vững vàng.",
			"Đường tới Vùng Đất đã mở.",
		],
	},
	&"light": {
		"guardian": "Light guardian",
		"goal": 3,
		"hud": "Thức tỉnh cột đá theo thứ tự: %d/%d",
		"offer": [
			"Cổng Ánh Sáng chỉ mở khi ba cột đá cổ được thức tỉnh đúng thứ tự.",
			"Hãy nhớ lời ta và chạm vào từng cột đá. Sai thứ tự, chúng sẽ ngủ lại.",
		],
		"reminder": ["Nghe lại lời chỉ dẫn của ta."],
		"complete": [
			"Ba cột đá đã cùng toả sáng! Ánh sáng đang chờ ngươi.",
			"Cổng tới Vùng Ánh Sáng đã mở.",
		],
	},
	&"air": {
		"guardian": "Air guardian",
		"goal": 3,
		"hud": "Bắt linh hồn gió: %d/%d",
		"offer": [
			"Một linh hồn gió đã trốn khỏi cổng của ta. Không có nó, cổng không thể mở.",
			"Nó rất nhanh. Hãy dùng Dash để đuổi kịp và chạm vào nó 3 lần.",
		],
		"reminder": ["Linh hồn gió vẫn lang thang trên đảo. Đừng quên dùng Dash."],
		"complete": [
			"Ngươi đã thuần phục được linh hồn gió! Nó sẽ dẫn đường cho ngươi.",
			"Cổng tới Vùng Gió đã mở.",
		],
	},
	&"life": {
		"guardian": "Life guardian",
		"goal": 4,
		"hud": "Nhận lời chúc của người gác: %d/%d",
		"offer": [
			"Sau cánh cổng này là Troll, kẻ mạnh nhất trong năm chúa tể.",
			"Trước khi đi, hãy nhận lời chúc của bốn người gác còn lại.",
		],
		"reminder": ["Ngươi vẫn chưa nhận đủ lời chúc của bốn người gác."],
		"complete": [
			"Ta cảm nhận được sức mạnh của cả bốn người gác trong ngươi.",
			"Hãy đi đi, người bảo hộ. Cả hòn đảo đặt niềm tin vào ngươi.",
		],
	},
}

const QUEST_RETURN_HUD := "Quay về gặp %s"

# Light quest riddle; each %s is a pillar spot's hint (set on the QuestSpots markers).
const LIGHT_RIDDLE := [
	"Cột thứ nhất nằm %s.",
	"Cột thứ hai nằm %s.",
	"Cột cuối cùng nằm %s.",
]

# Life quest: what each other guardian says when giving a blessing.
const LIFE_BLESSINGS := {
	&"water": "Biển đã trở lại trong lành nhờ ngươi. Hãy mang theo sự bình tĩnh của biển cả.",
	&"earth": "Đất dưới chân ngươi sẽ luôn vững vàng. Đi đi, và đừng chùn bước.",
	&"light": "Ánh sáng sẽ soi đường cho ngươi, kể cả trong bóng tối sâu nhất.",
	&"air": "Gió sẽ nâng bước chân ngươi. Chúc ngươi nhanh hơn mọi đòn đánh của Troll.",
}


static func load_story_image(file_name: String) -> Texture2D:
	var path := STORY_IMAGE_DIR + file_name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return load("res://icon.svg") as Texture2D
