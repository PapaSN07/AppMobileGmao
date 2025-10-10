# Utiliser une image Python basée sur Debian 11 (Bullseye) pour compatibilité avec le repo Microsoft
FROM python:3.11-slim-bullseye

# Installer les dépendances système pour cx_Oracle et pyodbc
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    gnupg \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer Oracle Instant Client (pour cx_Oracle)
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basic-linux.x64-19.23.0.0.0dbru.zip -O /tmp/instantclient.zip \
    && unzip /tmp/instantclient.zip -d /opt/oracle \
    && rm /tmp/instantclient.zip \
    && echo "/opt/oracle/instantclient_19_23" > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Installer Microsoft ODBC Driver for SQL Server (pour pyodbc) - CORRECTION
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64,armhf,arm64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

# Définir les variables d'environnement pour Oracle
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_19_23:${LD_LIBRARY_PATH}
ENV ORACLE_HOME=/opt/oracle/instantclient_19_23

# Créer un répertoire de travail
WORKDIR /app

# Copier et installer les dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY . .

# Créer un utilisateur non-root pour la sécurité
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Exposer le port FastAPI
EXPOSE 8000

# Commande de démarrage
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]