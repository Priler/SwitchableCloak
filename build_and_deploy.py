import os
import sys
import shutil
import subprocess
from pathlib import Path

def main():
    # Get the directory where the script is located
    script_dir = Path(getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__))))
    
    try:
        # 1. Run build.py and wait for completion
        print("Running build script...")
        build_script = script_dir / "build.py"
        subprocess.run([sys.executable, str(build_script)], check=True)
        
        # Define paths
        witcher3_path = Path(r"C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3")
        mod_path = witcher3_path / "Mods" / "mod_hoodsSwitchableCloak"
        config_file = witcher3_path / "bin" / "config" / "r4game" / "user_config_matrix" / "pc" / "SwitchableCloak.xml"
        
        # Verify Witcher 3 directory exists
        if not witcher3_path.exists():
            raise FileNotFoundError(f"Witcher 3 directory not found at: {witcher3_path}")
        
        # Delete config file if it exists
        print("Removing old config file...")
        if config_file.exists():
            config_file.unlink()
        
        # 2. Copy config file to Witcher 3 directory
        print("Copying config file...")
        local_config = script_dir / "bin" / "config" / "r4game" / "user_config_matrix" / "pc" / "SwitchableCloak.xml"
        if local_config.exists():
            # Ensure the destination directory exists
            config_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(local_config, config_file)
        else:
            raise FileNotFoundError(f"Config file not found at: {local_config}")
        
        # 3. Remove existing mod folder
        print("Removing old mod files...")
        if mod_path.exists():
            shutil.rmtree(mod_path)
        
        # 4. Copy new mod folder
        print("Installing new mod files...")
        mod_source = script_dir / "build" / "mod_hoodsSwitchableCloak"
        if mod_source.exists():
            shutil.copytree(mod_source, mod_path)
        else:
            raise FileNotFoundError(f"Mod source directory not found at: {mod_source}")
        
        # 5. Print completion message
        print("\nDeployment completed successfully!")
        input("Press Enter to exit...")
        
    except subprocess.CalledProcessError:
        print("Error: Build script failed to execute!")
        input("Press Enter to exit...")
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"Error: {e}")
        input("Press Enter to exit...")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        input("Press Enter to exit...")
        sys.exit(1)

if __name__ == "__main__":
    main()