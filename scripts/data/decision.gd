class_name Decision
extends Resource

@export var id: String
@export var era: int = 1
@export var testo_consigliere: String
@export var personaggio_id: String
@export var opzioni: Array[DecisionOption] = []
@export var tipo_decisione: String = "proposta_consigliere"
@export var illustrazione_id: String = ""
