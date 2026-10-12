# Agence CRM — mise en route

## 1. Base de données (Supabase, gratuit)
1. Créez un projet sur https://supabase.com
2. SQL Editor → collez tout `schema.sql` → Run
3. Project Settings → API : copiez l'URL et la clé « anon public » dans `index.html` (SB_URL, SB_KEY).
   La clé anon est faite pour être publique. Ne mettez JAMAIS la clé « service_role » dans ce dépôt.
4. Authentication → Providers → Email : désactivez « Confirm email » pour tester vite.

## 2. Mise en ligne sur GitHub Pages
1. Créez un dépôt GitHub (public : Pages est gratuit) et envoyez-y `index.html`, `schema.sql`, `README.md`
2. Settings → Pages → Source : « Deploy from a branch », branche `main`, dossier `/ (root)` → Save
3. Votre adresse : https://VOTRE-NOM.github.io/NOM-DU-DEPOT/
4. Retour dans Supabase → Authentication → URL Configuration : collez cette adresse dans « Site URL » et dans « Redirect URLs » (nécessaire pour « Mot de passe oublié »)

## 3. Premiers pas
1. Créez votre compte en premier : il devient admin. Votre ami crée le sien, puis vous cochez « Admin » dans l'onglet Admin.
2. Admin : ajoutez les modèles, donnez un rôle aux chatteurs, attribuez-leur modèle et shift, fixez leur commission.
3. Testez avec un compte chatteur : il ne doit voir que ses modèles, ses shifts, ses ventes et ses retraits.

## 4. Retraits
Le chatteur demande un retrait (MTN MoMo, Moov Money, Celtiis Cash, virement, USDT TRC-20/BEP-20/Solana, USDC Solana/ERC-20, Ethereum ou Bitcoin) dans la limite de son solde.
L'admin paie depuis son propre compte, puis passe la demande en « Payé » avec la référence de la transaction.

Pour les cryptos : envoyez le montant converti au cours du jour depuis votre portefeuille ou plateforme, puis notez le hash de la transaction dans « Référence ». Vérifiez la réglementation locale applicable.
