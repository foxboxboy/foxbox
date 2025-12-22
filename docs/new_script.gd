
# tates_library/docs/naming_conventions.gd
# ==========================================================
# AI DISCLAIMER: many of these terms are partially or entirely 
# done with research and organization from Google Gemini.

#region I. ATOMIC LAYER (The Building Blocks)
# ----------------------------------------------------------
## 1. Component
#    Definition: The "Attribute" or "Tool." Manages a single domain of state.
#    Responsibility: Encapsulating specific functionality (e.g., Health, Timer).
#    Design Rule: Atomic and decoupled. Should not "know" about other components.

## 2. Resource
#    Definition: The "Blueprint." Pure data containers.
#    Responsibility: Storing configurations or blueprints (e.g., WeaponData, SaveData).
#    Logic: Restricted to data validation. Should be serializable.
#endregion

#region II. EXECUTION LAYER (The "Do-ers")
# ----------------------------------------------------------
## 3. Motor
#    Definition: The "Muscles." Translates abstract intent into engine-level action.
#    Responsibility: Handling physics, movement, or value interpolation.
#    Design Rule: Acts on a target. Receives "Intent Data" from a Controller.

## 4. Controller
#    Definition: The "Brain." Processes inputs or rules to issue commands.
#    Responsibility: Input processing (WASD/Mouse) or AI Logic (Pathfinding).
#    Design Rule: Interprets *why* something happens and tells the Motor *what* to do.
#endregion

#region III. COORDINATION LAYER (The "Bridges")
# ----------------------------------------------------------
## 5. Handler
#    Definition: The "Glue." Coordinates interaction between multiple modules.
#    Responsibility: Linking generic modules to specific game rules (e.g., CombatHandler).
#    Design Rule: Listens to signals from one module and executes logic on another.

## 6. Provider
#    Definition: The "Interface." Standardized API to access complex internal data.
#    Responsibility: Acting as a clean "window" for external data requests.
#    Why it exists: Decouples internal mess from external need for simple values.
#endregion

#region IV. VISUAL LAYER (The "Aesthetics")
# ----------------------------------------------------------
## 7. View / Visualizer
#    Definition: The "Skin." Dedicated strictly to aesthetics and feedback.
#    Responsibility: Handling particles, mesh swapping, and "juice."
#    Rule: Strictly Read-Only. Never changes gameplay state; only shows it.
#endregion

#region V. GLOBAL LAYER (The "Systems")
# ----------------------------------------------------------
## 8. Manager
#    Definition: The "God View." Handles groups of entities and global states.
#    Responsibility: Spawning, Selection, Win/Loss conditions, and Ownership.
#    Design Rule: A Manager "owns" its children or its data set.

## 9. Service
#    Definition: The "Utility." Global, stateless toolset.
#    Responsibility: Pure logic (Math, Sound triggers, Pathfinding calculations).
#    Key Difference: A Manager *owns* things; a Service just *does* things.
#endregion

#region VI. COMMUNICATION MANIFESTO
# ----------------------------------------------------------
## 1. Direct Calls Down
#    A parent (or higher layer) calls a child's function.
## 2. Signals Up
#    A child (or lower layer) emits a signal to notify the parent.
## 3. Cross-Talk through Bridges
#    Two modules on the same level use a Handler or Manager to communicate.
## 4. Visual Silence
#    A View can read data, but it must never write it.
#endregion

#region VII. EXAMPLES
# ----------------------------------------------------------
## In a Racing Game: 
#	The WheelMotor moves the car, the PlayerController reads the steering wheel, and the LapManager tracks the progress.
## In a Main Menu: 
#	The ScrollMotor moves the list, the MenuHandler switches between sub-menus, and the AudioService plays the click sounds.
## In a Save System: 
#	The SaveData (Resource) is passed to the SaveService (Utility), which writes it to the disk.
