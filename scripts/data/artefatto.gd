class_name Artefatto
extends Resource

@export var id: String
@export var nome: String
@export var descrizione: String
@export var icona: Texture2D
@export var effetto_inizio_run: Effect
@export var sblocca_dialoghi: Array[String] = []
@export var sblocca_finali: Array[String] = []
