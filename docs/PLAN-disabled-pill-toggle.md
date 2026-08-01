# Piano: Toggle "Disabilita pillola" nella schermata edit

## Obiettivo
Permettere all'utente di disabilitare una pillola senza eliminarla:
- Non invia più notifiche
- Compare come disabilitata nella lista home (opacità ridotta, icona diversa)
- Non appare nella sezione "Da assumere" (overdue)
- Toggle nella schermata di edit/aggiunta pillola

## Cambiamenti

### 1. Database — nuova colonna `is_disabled`
**File:** `lib/data/app_database.dart`

- Incrementare `version` da 3 a 4
- Aggiungere migrazione `onUpgrade`: `ALTER TABLE pills ADD COLUMN is_disabled INTEGER DEFAULT 0`
- Aggiungere `is_disabled INTEGER DEFAULT 0` al `CREATE TABLE` (per nuovi install)
- Aggiornare `Pill` model:
  - Nuovo campo `final bool isDisabled;`
  - Aggiornare `toMap()`, `fromMap()`, `copyWith()`
  - Default `false`
- Aggiornare `insertPill()` per accettare `isDisabled`
- Aggiornare query `getAllPills()` (la colonna viene letta automaticamente con `SELECT p.*`)

### 2. PillService — gestire notifiche in base allo stato
**File:** `lib/services/pill_service.dart`

- `addPill()`: se `isDisabled == true`, non schedulare notifica
- `updatePill()`:
  - Se la pillola è ora disabilitata → `cancelNotification()`
  - Se la pillola è ora abilitata → `scheduleDailyNotification()`
  - Se lo stato non è cambiato → schedulare come prima (per ricreare con eventuale nuovo orario)
- `getOverduePills()`: saltare le pillole disabilitate

### 3. Schermata edit — toggle disabilita
**File:** `lib/screens/add_pill_screen/add_pill_screen.dart`

- Aggiungere stato `bool _isDisabled` inizializzato da `widget.pill?.isDisabled ?? false`
- Aggiungere un `SwitchListTile` (o simile) tra `TotalDosesField` e il pulsante Salva:
  - Titolo: "Disabilita"
  - Sottotitolo: "Non inviare notifiche per questa pillola"
  - Valore: `_isDisabled`
- Nel `_save()`, passare `isDisabled: _isDisabled` a `addPill()` e `copyWith()`

### 4. UI lista home — mostrare stato disabilitato
**File:** `lib/screens/home_screen/pills_list_section.dart`

- In `PillCardWidget.build()`:
  - Se `pill.isDisabled`: opacità ridotta (`Opacity` ~0.5), icona grigia invece di blu, eventuale etichetta "Disabilitata" nel subtitle
  - Mantenere edit/delete funzionanti

### 5. Sezione overdue — già gestita
**File:** `lib/screens/home_screen/overdue_section.dart`

- Nessun cambiamento necessario: `PillService.getOverduePills()` filtra già le disabilitate

## Riepilogo file modificati
1. `lib/data/app_database.dart` — colonna, modello, migrazione
2. `lib/services/pill_service.dart` — logica notifiche + filtro overdue
3. `lib/screens/add_pill_screen/add_pill_screen.dart` — toggle UI
4. `lib/screens/home_screen/pills_list_section.dart` — visualizzazione disabilitata
