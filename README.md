<h1 align="center">
  <br>
<div style="width:312px; height:312px; border-radius:50%; overflow:hidden; border:4px solid #333; margin: 0 auto; display:flex; align-items:center; justify-content:center;">
  <img src="https://placedog.net/512" alt="Round Image" style="width:100%; height:100%; object-fit:cover;">
</div>
  PSLinkSmith
  <br>
</h1>

<h4 align="center">A bare-bones symlink farm manager for Windows built with <a href="https://learn.microsoft.com/en-us/dotnet/desktop/winforms/overview/?view=netframeworkdesktop-4.8" target="_blank">Windows Forms (.NET Framework)</a> and PowerShell.</h4>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/version-1.0.0-blue.svg" alt="Version"></a>
  <a href="#"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"></a>
  <a href="#"><img src="https://img.shields.io/badge/build-passing-brightgreen.svg" alt="Build"></a>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#download">Download</a> •
  <a href="#credits">Credits</a> •
  <a href="#related">Related</a> •
  <a href="#license">License</a>
</p>

<div align="center">
  <img src="https://placedog.net/800x300" alt="Image">
</div>

## 📂 About

**LinkSmith** is a minimalist/bare-bones project to manage symlink farms on Windows using PowerShell and Windows Forms. This was developed as a study of GUI interaction with PowerShell, inspired by UNIX-like tools such as [GNU Stow](https://www.gnu.org/software/stow/) and [Dotbot](https://github.com/anishathalye/dotbot).

The goal was to experiment with **Windows Forms** to create a functional interface for symlink deployment—something rarely seen for this kind of task in the Windows ecosystem.

## ⚙️ Key Features

* 🗂️ **Create Symlinks** – Quickly set up symlinks for configuration or project directories.
* 💻 **Simple GUI** – Built with Windows Forms (classic .NET Framework).
* 🔎 **Directory Preview** – See the directory structure before spawning links.
* 🪢 **Recursive Linking** – Supports linking entire directory trees.
* 🪟 **Pure PowerShell Integration** – Uses native PowerShell + WinForms.

## 🚀 How To Use

Requires **PowerShell** (≥ 5.1) and **.NET Framework 4.8+**.

```powershell
# Clone this repository
git clone https://github.com/brunohaf/LinkSmith

# Run the script
cd LinkSmith
.\LinkSmith.ps1
````

> ⚠️ **Note**
> Running unsigned scripts may require adjusting your execution policy:
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## 📦 Download

You can [download the latest release](https://github.com/brunohaf/PSLinkSmith/releases) or clone the repository manually.

## 🙏 Credits

This project uses:

* [.NET Framework (WinForms)](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/overview/?view=netframeworkdesktop-4.8)
* PowerShell

## 🔗 Related

* [GNU Stow](https://www.gnu.org/software/stow/) – Symlink farm manager (Unix)
* [Dotbot](https://github.com/anishathalye/dotbot) – Dotfile management (Unix)
* [Scoop](https://scoop.sh/) – Package manager for Windows with symlink use

## 📃 License

MIT License

---

> GitHub [@brunohaf](https://github.com/brunohaf)
