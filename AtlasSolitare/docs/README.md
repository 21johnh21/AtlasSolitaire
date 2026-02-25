# Atlas Solitaire Website Setup

This folder contains the marketing website, support pages, and privacy policy for Atlas Solitaire.

## 🌐 GitHub Pages Setup (5 Minutes)

### Step 1: Push to GitHub

1. Initialize git repository (if not already done):
```bash
cd /Users/johnhawley/Documents/src/AtlasSolitaire/AtlasSolitare
git init
git add .
git commit -m "Initial commit with website"
```

2. Create a new repository on GitHub:
   - Go to https://github.com/new
   - Name it: `atlas-solitaire` (or your preferred name)
   - Make it public
   - DON'T initialize with README (you already have one)

3. Push your code:
```bash
git remote add origin https://github.com/YOUR_USERNAME/atlas-solitaire.git
git branch -M main
git push -u origin main
```

### Step 2: Enable GitHub Pages

1. Go to your GitHub repository
2. Click **Settings**
3. Scroll to **Pages** (left sidebar)
4. Under **Source**, select:
   - Branch: `main`
   - Folder: `/docs`
5. Click **Save**

### Step 3: Wait 2-3 Minutes

GitHub will build your site. Refresh the Settings → Pages page until you see:

```
✅ Your site is live at https://YOUR_USERNAME.github.io/atlas-solitaire/
```

## 📋 URLs for App Store Connect

Once GitHub Pages is live, use these URLs:

### Marketing URL (Optional)
```
https://YOUR_USERNAME.github.io/atlas-solitaire/
```

### Support URL (Required)
```
https://YOUR_USERNAME.github.io/atlas-solitaire/support.html
```

### Privacy Policy URL (Required for AdMob)
```
https://YOUR_USERNAME.github.io/atlas-solitaire/privacy.html
```

## ✏️ Customization

### Update Email Addresses

Before going live, replace placeholder emails in the HTML files:

**In `support.html`:**
- `support@atlassolitaire.com` → Your real support email
- `feedback@atlassolitaire.com` → Your feedback email
- `bugs@atlassolitaire.com` → Your bug report email

**In `privacy.html`:**
- `privacy@atlassolitaire.com` → Your privacy email

### Update App Store Link

In `index.html`, replace:
```html
<a href="https://apps.apple.com/app/atlas-solitaire" class="cta">Download on App Store</a>
```

With your actual App Store URL once published.

## 📱 Where to Use These URLs

### App Store Connect

1. **App Information** → Support URL:
   ```
   https://YOUR_USERNAME.github.io/atlas-solitaire/support.html
   ```

2. **App Information** → Marketing URL (optional):
   ```
   https://YOUR_USERNAME.github.io/atlas-solitaire/
   ```

3. **App Privacy** → Privacy Policy URL:
   ```
   https://YOUR_USERNAME.github.io/atlas-solitaire/privacy.html
   ```

### AdMob Console

When setting up your app in AdMob:

1. Go to Apps → Your App → App Settings
2. Add Privacy Policy URL:
   ```
   https://YOUR_USERNAME.github.io/atlas-solitaire/privacy.html
   ```

## 🎨 Customization Tips

### Colors
The current color scheme uses:
- Primary: `#667eea` (purple-blue)
- Secondary: `#764ba2` (deep purple)

To change colors, search for these hex codes in the HTML files and replace them.

### Content
All content is in the HTML files. Simply edit the text between the tags:
- `index.html` - Main landing page
- `support.html` - FAQ and support info
- `privacy.html` - Privacy policy

### Logo/Images
To add images:
1. Put images in the `docs/` folder
2. Reference them in HTML: `<img src="logo.png">`

## 🔒 Custom Domain (Optional)

Want to use `atlassolitaire.com` instead of GitHub Pages?

1. Buy domain from Namecheap, GoDaddy, etc.
2. In your domain settings, add DNS records:
   ```
   CNAME  www  YOUR_USERNAME.github.io
   A      @    185.199.108.153
   A      @    185.199.109.153
   A      @    185.199.110.153
   A      @    185.199.111.153
   ```
3. In GitHub Settings → Pages → Custom domain, enter: `atlassolitaire.com`
4. Wait 24-48 hours for DNS propagation

## 📞 Email Setup

For professional email addresses like `support@atlassolitaire.com`:

### Free Option: Gmail Forwarding
1. Buy domain (e.g., Namecheap $12/year)
2. Set up email forwarding to your Gmail
3. Reply from Gmail using "Send mail as"

### Paid Option: Google Workspace
- $6/month for professional email
- `support@atlassolitaire.com`, `privacy@atlassolitaire.com`, etc.

### Alternative: Use Existing Email
Just use your current email (e.g., `yourname@gmail.com`) in all the HTML files. It works fine for small apps!

## ✅ Checklist

Before submitting to App Store:

- [ ] Push website to GitHub
- [ ] Enable GitHub Pages
- [ ] Verify all 3 pages load correctly
- [ ] Update placeholder email addresses
- [ ] Test support URL
- [ ] Test privacy URL
- [ ] Add URLs to App Store Connect
- [ ] Add privacy URL to AdMob Console

## 🆘 Troubleshooting

**GitHub Pages not working?**
- Wait 5 minutes after enabling
- Check Settings → Pages for error messages
- Make sure `docs/` folder exists on main branch
- Verify index.html is in `docs/` folder

**404 errors?**
- URLs are case-sensitive
- Use `/support.html` not `/Support.html`
- Make sure files are in `docs/` folder

**Need help?**
- GitHub Pages Docs: https://docs.github.com/en/pages
- GitHub Pages is completely free for public repositories

---

Your website is ready to go! 🚀
