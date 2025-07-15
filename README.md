<p align="center"> 
  <br/>
  <a href="https://opensource.org/license/agpl-v3">
    <img src="https://img.shields.io/badge/License-AGPL_v3-blue.svg?color=3F51B5&style=for-the-badge&label=License&logoColor=000000&labelColor=ececec" alt="License: AGPLv3">
  </a>
  <a href="https://discord.rpictures.app">
    <img src="https://img.shields.io/discord/979116623879368755.svg?label=Discord&logo=Discord&style=for-the-badge&logoColor=000000&labelColor=ececec" alt="Discord"/>
  </a>
  <br/>
  <br/>
</p>

<p align="center">
  <img src="design/rpictures-logo.svg" width="300" title="rPictures Logo">
</p>

<h3 align="center">Composant self-hosted de gestion de photos et vidéos</h3>
<br/>

<a href="https://rpictures.app">
  <img src="design/rpictures-screenshots.png" title="Main Screenshot">
</a>
<br/>

<p align="center">
  <a href="readme_i18n/README_fr_FR.md">Français</a>
  <a href="readme_i18n/README_en_US.md">English</a>
</p>

<h2>Disclaimer</h2>
<ul>
  <li>⚠️ Projet <strong>très actif</strong>, suivez les releases.</li>
  <li>⚠️ Préparez toujours un plan de sauvegarde 3-2-1 pour vos données.</li>
</ul>

<blockquote>
  <p><strong>NOTE</strong><br/>
  Documentation principale: <a href="https://rpictures.app/docs">https://rpictures.app/docs</a></p>
</blockquote>

<h2>A propos de ce dépôt</h2>
<p><strong>rPictures</strong> fait partie de <strong>Ryvie</strong> et contient :</p>
<ul>
  <li><code>docker/</code> : backend (API, Postgres) packagé avec Docker Compose.</li>
  <li><code>mobile/</code> : application Flutter iOS.</li>
</ul>

<hr/>

<h2>🚀 Installation du backend (Docker Compose)</h2>
<pre><code>git clone https://github.com/maisonnavejul/Ryvie-rPictures.git
cd Ryvie-rPictures/docker
cp .env.example .env  # ajustez UPLOAD_LOCATION, DB_PASSWORD, etc.
docker compose -f docker-compose.ryvie.yml up -d
curl -I http://localhost:2283  # doit renvoyer HTTP/1.1 200 OK
</code></pre>

<hr/>

<h2>📱 Compilation de l’app iOS</h2>
<pre><code>cd mobile
flutter clean
flutter pub get
flutter build ios --no-codesign
open ios/Runner.xcworkspace
</code></pre>
<p>Ouvrez ensuite Xcode, choisissez votre cible et déployez.</p>

<hr/>

<h2>Liens</h2>
<ul>
  <li><strong>Dépôt GitHub</strong>: <a href="https://github.com/maisonnavejul/Ryvie-rPictures">github.com/maisonnavejul/Ryvie-rPictures</a></li>
  <li><strong>Docs</strong>: <a href="https://rpictures.app/docs">https://rpictures.app/docs</a></li>
  <li><strong>Roadmap</strong>: <a href="https://rpictures.app/roadmap">https://rpictures.app/roadmap</a></li>
</ul>

<hr/>

<h2>License</h2>
<p>© 2025 Ryvie<br/>
Distribué sous <strong>GNU AGPL v3.0</strong> — <a href="https://www.gnu.org/licenses/agpl-3.0.en.html">Texte complet</a></p>

<hr/>

<p>Rejoignez-nous sur Discord: <a href="https://discord.rpictures.app">https://discord.rpictures.app</a></p>
