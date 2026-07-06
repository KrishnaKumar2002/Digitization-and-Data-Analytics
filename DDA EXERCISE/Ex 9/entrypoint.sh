#!/bin/bash

# Match container user to host user so file permissions work on the mounted volume
if [ -n "${HOST_UID}" ] && [ -n "${HOST_GID}" ]; then
    groupmod -o -g "${HOST_GID}" "dda" 2>/dev/null || true
    usermod -o -u "${HOST_UID}" "dda" 2>/dev/null || true
fi

# Ensure the mounted notebooks directory is writable by the application user
chown -R "dda:dda" "/home/dda/notebooks"

cat > /srv/jupyterhub/jupyterhub_config.py << PYEOF
c = get_config()
c.JupyterHub.bind_url = 'http://0.0.0.0:8000'
c.JupyterHub.base_url = '/'
c.JupyterHub.authenticator_class = 'dummy'
c.DummyAuthenticator.password = ''
c.JupyterHub.allow_named_servers = True
c.Authenticator.allow_all = True
c.Spawner.notebook_dir = '/home/dda/notebooks'
PYEOF

# Start JupyterHub
exec jupyterhub --config=/srv/jupyterhub/jupyterhub_config.py

