import zipfile
import json
import os
import shutil
model_path = '../lstm_air_quality_model_fixed.keras'
temp_dir = 'temp_model_fix'
fixed_model_path = 'lstm_air_quality_model_v2.keras'

# 1. Extract the .keras file (it's actually a zip)
with zipfile.ZipFile(model_path, 'r') as zip_ref:
    zip_ref.extractall(temp_dir)

# 2. Load the configuration
config_path = os.path.join(temp_dir, 'config.json')
with open(config_path, 'r') as f:
    model_config = json.load(f)

# 3. Recursively find and fix 'batch_shape' -> 'batch_input_shape'
def fix_config(obj):
    if isinstance(obj, dict):
        if 'batch_shape' in obj:
            obj['batch_input_shape'] = obj.pop('batch_shape')
        for key, value in obj.items():
            fix_config(value)
    elif isinstance(obj, list):
        for item in obj:
            fix_config(item)

fix_config(model_config)

# 4. Save the fixed config back
with open(config_path, 'w') as f:
    json.dump(model_config, f)

# 5. Re-zip into a new .keras file
with zipfile.ZipFile(fixed_model_path, 'w') as zip_f:
    for root, dirs, files in os.walk(temp_dir):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, temp_dir)
            zip_f.write(file_path, arcname)

# Cleanup
shutil.rmtree(temp_dir)
print(f"✅ Success! New model saved as: {fixed_model_path}")
print("Now update your app.py to load 'lstm_air_quality_model_v2.keras'")