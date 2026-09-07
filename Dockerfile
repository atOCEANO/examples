FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /work

# For the client pin in requirements.txt, which pip resolves over git.
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Before requirements.txt, so resolving the sb3 extra finds torch already there.
# The CPU index because the default wheel carries a CUDA runtime of several
# gigabytes that nothing here can reach.
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch

# Not the workdir: compose mounts the repo over /work, shadowing anything there.
COPY requirements.txt /tmp/requirements.txt

# ipywidgets so optuna's tqdm import finds a progress widget. Without it the
# first cell of the search notebook opens with a warning about updating jupyter.
RUN pip install --no-cache-dir -r /tmp/requirements.txt jupyterlab==4.6.3 ipywidgets==8.1.7

# uid 1000 so notebooks written back through the mount are not root owned.
RUN useradd --create-home --uid 1000 appuser && chown -R appuser /work
USER appuser

# Safe because compose publishes this on loopback only.
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--IdentityProvider.token="]
