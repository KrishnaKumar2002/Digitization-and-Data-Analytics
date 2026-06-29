#!/bin/bash
set -e

echo "=============================================================="
echo " Setting Modules"
echo "=============================================================="
module purge

MODULES="release/24.04 GCC/13.2.0 Python/3.11.5 Spark/3.5.0-hadoop3"
module load $MODULES
sleep 2s

echo "=============================================================="
echo " Setting Kernel"
echo "=============================================================="
# Sourcing the virtual environment
VENV_PATH="${1:-"/projects/p_lv_dda_26/.venv"}"

echo "Activating virtual environment: $VENV_PATH"
source $VENV_PATH/bin/activate

# Installing kernel
PYTHON_KERNEL_NAME="${2:-"big-data-dda-kernel"}"
PYTHON_KERNEL_DIR="$HOME/.local/share/jupyter/kernels/$PYTHON_KERNEL_NAME"

echo "Installing kernel"
python -m ipykernel install --user --name "$PYTHON_KERNEL_NAME" --display-name="$PYTHON_KERNEL_NAME"

# Creating kerenel initialization script
echo "Creating kerenel initialization script."

# Placing kernel initialization script in the kernel directory
KERNEL_INIT_SCRIPT="$PYTHON_KERNEL_DIR/kernel-init.sh"

# Creating a kernel initialization script
echo "Creating kernel intialization script."
cat << EOF > $KERNEL_INIT_SCRIPT
#!/bin/bash

CONNFILE=\${1}

set -euo pipefail

echo "========================================================="
echo "Starting kernel: $PYTHON_KERNEL_NAME"

module reset

module load $MODULES

PYVENV_PATH=$VENV_PATH

source \$PYVENV_PATH/bin/activate

python -m ipykernel_launcher -f \${CONNFILE}

echo "========================================================="
# End of the script
EOF

chmod u+rwx $KERNEL_INIT_SCRIPT

# Replace the contents of kernel.json file
echo "Replacing contents of $PYTHON_KERNEL_DIR/kernel.json"
cat << EOF > "$PYTHON_KERNEL_DIR/kernel.json"
{
  "argv": [
    "$KERNEL_INIT_SCRIPT",
    "{connection_file}"
  ],
  "display_name": "$PYTHON_KERNEL_NAME",
  "language": "python",
  "metadata": {
    "debugger": true
  }
}
EOF

echo "Kernel installation complete."


echo "=============================================================="
echo " Resetting the modules and environment"
echo "=============================================================="
deactivate
module reset
sleep 1s

echo "=============================================================="
echo " Next steps"
echo "=============================================================="
echo "1. Re-load the browser"
echo "2. Open the notebook"
echo "3. Select the \"$PYTHON_KERNEL_NAME\": Top Menu -> Kernel -> Change Kernel"

# End of the script
