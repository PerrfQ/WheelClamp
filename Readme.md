# Wheel Clamp Script for FiveM

A lightweight script for FiveM that allows players to apply and remove wheel clamps on vehicles, immobilizing them to prevent movement. Ideal for roleplay servers where law enforcement needs to enforce parking rules or detain vehicles.

## Features
- **Apply/Remove Clamps**: Use `/wheelclamp` to apply a clamp and `/removewheelclamp` to remove it (commands can be disabled in `config.lua`).
- **Job Restrictions**: Limit clamp usage to specific jobs (e.g., `police`) using ESX or Standalone frameworks.
- **Framework Support**: Compatible with ESX or Standalone setups. *Note: QBCore support is on the TODO list and not yet finalized.*
- **Tablet/Menu Integration**: Export functions (`ApplyClamp`, `RemoveClamp`) for integration with police tablets or menus.
- **Persistent Clamps**: Clamps are saved to a database (`oxmysql`) and persist through server restarts.
- **Visual Feedback**: A wheel clamp prop (`prop_spot_clamp`) is attached to the vehicle's front-left wheel at position `x = -0.1, y = 0.0, z = 0.4`.
- **Performance**: Idle at 0.00ms, with 0.15ms when a player attempts to brake a clamped vehicle.

## Requirements
- **FiveM Server** with `oxmysql` for database storage.
- **ESX** (optional, if not using Standalone mode). Ensure the framework is running before this script.
- A database with the `wheel_clamps` table (SQL provided below).

## Installation

1. **Download the Script**:
   - Clone or download this repository to your server's `resources` folder.

2. **Set Up the Database**:
   - Ensure `oxmysql` is installed and running.
   - Import the following SQL to create the `wheel_clamps` table:
     ```sql
     CREATE TABLE IF NOT EXISTS `wheel_clamps` (
         `plate` VARCHAR(50) NOT NULL,
         PRIMARY KEY (`plate`)
     );
     ```

3. **Configure the Script**:
   - Open `config.lua` and adjust the settings:
     - `Config.DebugMode`: Set to `true` for debug logs, `false` for production.
     - `Config.ESX`, `Config.QBCore`, `Config.Standalone`: Enable only one framework (`true` for the one you're using, `false` for others). *Note: QBCore is not fully supported yet.*
     - `Config.EnableCommands`: Set to `true` to enable `/wheelclamp` and `/removewheelclamp` commands, or `false` to disable them (e.g., if using a tablet).
     - `Config.JobName`: Set the job name required to apply/remove clamps (e.g., `police`).

4. **Update `fxmanifest.lua`**:
   - If using ESX, uncomment `'es_extended'` in the `dependencies` section.
   - If using QBCore, note that support is not yet finalized (on TODO list).

5. **Add to Server**:
   - Ensure the following resources are in your `server.cfg`:
     ```plaintext
     ensure oxmysql
     ensure es_extended  # If using ESX
     ensure Clamp
     ```
   - Make sure `Clamp` is started **after** `oxmysql` and your framework.

6. **Restart the Server**:
   - Restart your server or use `refresh` followed by `start Clamp` to load the script.

## Usage

### Commands
- `/wheelclamp`: Applies a wheel clamp to the nearest vehicle (if `Config.EnableCommands = true`).
- `/removewheelclamp`: Removes a wheel clamp from the nearest vehicle (if `Config.EnableCommands = true`).

**Note**: Commands are restricted to players with the job specified in `Config.JobName` (e.g., `police`). If the player doesn't have the required job, they'll receive a "You are not authorized to perform this action!" message.

### Tablet/Menu Integration
You can integrate this script with a police tablet or menu using the provided exports:

- **Apply a Clamp**:
  ```lua
  exports['Clamp']:ApplyClamp()