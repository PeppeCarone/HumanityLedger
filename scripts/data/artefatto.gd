class_name Artefatto
extends Resource

@export var id: String
@export var nome: String
@export var descrizione: String
@export var icona: Texture2D
@export var effetto_inizio_run: Effect
@export var sblocca_dialoghi: Array[String] = []
@export var sblocca_finali: Array[String] = []
# Se true, con l'artefatto equipaggiato le card-opzione mostrano la stat rinforzata.
@export var mostra_hint_stat: bool = false
# Testo mostrato sulla card del Ledger finché l'artefatto è bloccato.
@export var sblocco_hint: String = ""
