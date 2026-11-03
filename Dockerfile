FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /work

# git for the router, which requirements.txt installs from its tag, and the typeface
# oceano.mplstyle draws the figures in.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git fonts-jetbrains-mono \
    && rm -rf /var/lib/apt/lists/*

# Before requirements.txt, so resolving stable-baselines3 finds torch already there. The
# CPU index because the default wheel carries a CUDA runtime of several gigabytes, and
# pinned because the reinforcement-learning notebooks' outputs were produced against it.
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch==2.15.0+cpu

# Not the workdir: compose mounts the repo over /work, shadowing anything there.
COPY requirements.txt /tmp/requirements.txt

# The notebook server and its widgets go beside the libraries rather than into
# requirements.txt, since a reader's own Python may already serve notebooks. Without the
# widgets, the tqdm that Optuna imports warns in every notebook that searches.
RUN pip install --no-cache-dir -r /tmp/requirements.txt jupyterlab==4.6.5 ipywidgets==8.1.9

# uid 1000 so notebooks written back through the mount are not root owned.
RUN useradd --create-home --uid 1000 appuser && chown -R appuser /work
USER appuser

# Built here rather than by the first figure a notebook draws, which would otherwise print
# that matplotlib is building its font cache.
RUN python -c "import matplotlib.font_manager"

# Safe because compose publishes this on loopback only.
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--IdentityProvider.token="]
