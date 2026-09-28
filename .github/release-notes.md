## Install
1. Download **SKey-{{VERSION}}.dmg** below (or the `.zip`), open it and drag **SKey.app** into **Applications**.
2. Open SKey. macOS will say **"SKey" Not Opened: Apple could not verify "SKey" is free of malware…**
   This is the **normal prompt for any app that is not notarized by Apple**; it does not mean Apple found malware (SKey is released for free, without notarization). To be sure, [verify the download](#verify-the-download) first.
   - Click **Done** (not *Move to Trash*).
   - Open **System Settings → Privacy & Security**, scroll to **Security**, click **Open Anyway** next to *"SKey" was blocked…*, and confirm with your password or Touch ID.
   - Or run: `xattr -dr com.apple.quarantine /Applications/SKey.app`
3. Follow the **SKey setup** window: grant **Accessibility**, keep only the **ABC** input source (remove Simple Telex), and turn off macOS spelling correction and inline predictions.

**Upgrading from an earlier version:** quit SKey, replace it in Applications, and open it again. macOS treats each build as a new app, so the old Accessibility permission no longer applies: in the setup window click **Làm mới quyền** (Refresh permission), then turn SKey on again.

## Verify the download
These files are built by GitHub Actions straight from the source in this repository and carry a build provenance attestation. Check with the [GitHub CLI](https://cli.github.com):
```
gh attestation verify SKey-{{VERSION}}.dmg -R SLyHuy/SKey
```
Or compare the checksum:
```
shasum -a 256 SKey-{{VERSION}}.dmg
```
with the matching line in `SKey-{{VERSION}}.sha256`.

---
**SKey**: a minimal Vietnamese Telex input method for macOS, made for developers. No network access, no keystroke logging.
GPL-3.0 © 2026 Huy Ly · Source: https://github.com/SLyHuy/SKey · Report a vulnerability: [SECURITY.md](https://github.com/SLyHuy/SKey/blob/master/SECURITY.md)
