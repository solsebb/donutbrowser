<div align="center">
  <img src="assets/logo.png" alt="TwitterBrowser Logo" width="150">
  <h1>TwitterBrowser</h1>
  <strong>A powerful anti-detect browser fork that puts you in control of your browsing experience.</strong>
</div>
<br>

<p align="center">
  <a style="text-decoration: none;" href="https://github.com/solsebb/donutbrowser/releases/latest" target="_blank"><img alt="GitHub release" src="https://img.shields.io/github/v/release/solsebb/donutbrowser">
  </a>
  <a style="text-decoration: none;" href="https://github.com/solsebb/donutbrowser/issues" target="_blank">
    <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat" alt="PRs Welcome">
  </a>
  <a style="text-decoration: none;" href="https://github.com/solsebb/donutbrowser/blob/main/LICENSE" target="_blank">
    <img src="https://img.shields.io/badge/license-AGPL--3.0-blue.svg" alt="License">
  </a>
  <a style="text-decoration: none;" href="https://github.com/solsebb/donutbrowser/stargazers" target="_blank">
    <img src="https://img.shields.io/github/stars/solsebb/donutbrowser?style=social" alt="GitHub stars">
  </a>
</p>

<img alt="TwitterBrowser Preview" src="assets/donut-preview.png" />

## Features

- Create unlimited number of local browser profiles completely isolated from each other
- Safely use multiple accounts on one device by using anti-detect browser profiles, powered by [Camoufox](https://camoufox.com)
- Proxy support with basic auth for all browsers
- Import profiles from your existing browsers
- Automatic updates for browsers
- Set TwitterBrowser as your default browser to control in which profile to open links

## Download

> For Linux, .deb and .rpm packages are available as well as standalone .AppImage files.

The app can be downloaded from the [releases page](https://github.com/solsebb/donutbrowser/releases/latest).

<details>
<summary>Troubleshooting AppImage on Linux</summary>

If the AppImage segfaults on launch, install **libfuse2** (`sudo apt install libfuse2` / `yay -S libfuse2` / `sudo dnf install fuse-libs`), or bypass FUSE entirely:

```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./TwitterBrowser_x.x.x_amd64.AppImage
```

If that gives an EGL display error, try adding `WEBKIT_DISABLE_DMABUF_RENDERER=1` or `GDK_BACKEND=x11` to the command above. If issues persist, the **.deb** / **.rpm** packages are a more reliable alternative.

</details>

<!-- ## Supported Platforms

- ✅ **macOS** (Apple Silicon)
- ✅ **Linux** (x64)
- ✅ **Windows** (x64) -->

## Development

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Issues

If you face any problems while using the application, please [open an issue](https://github.com/solsebb/donutbrowser/issues).

## Self-Hosting Sync

TwitterBrowser supports syncing profiles, proxies, and groups across devices via a self-hosted sync server. See the [Self-Hosting Guide](docs/self-hosting-donut-sync.md) for Docker-based setup instructions.

## Community

Have questions or want to contribute? The team would love to hear from you!

- **Issues**: [GitHub Issues](https://github.com/solsebb/donutbrowser/issues)
- **Discussions**: [GitHub Discussions](https://github.com/solsebb/donutbrowser/discussions)

## Star History

<a href="https://www.star-history.com/#solsebb/donutbrowser&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=solsebb/donutbrowser&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=solsebb/donutbrowser&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=solsebb/donutbrowser&type=Date" />
 </picture>
</a>

## Contributors

<!-- readme: collaborators,contributors -start -->
<table>
	<tbody>
		<tr>
            <td align="center">
                <a href="https://github.com/zhom">
                    <img src="https://avatars.githubusercontent.com/u/2717306?v=4" width="100;" alt="zhom"/>
                    <br />
                    <sub><b>zhom</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/HassiyYT">
                    <img src="https://avatars.githubusercontent.com/u/81773493?v=4" width="100;" alt="HassiyYT"/>
                    <br />
                    <sub><b>Hassiy</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/JorySeverijnse">
                    <img src="https://avatars.githubusercontent.com/u/117462355?v=4" width="100;" alt="JorySeverijnse"/>
                    <br />
                    <sub><b>Jory Severijnse</b></sub>
                </a>
            </td>
		</tr>
	<tbody>
</table>
<!-- readme: collaborators,contributors -end -->

## Contact

Have an urgent question or want to report a security issue? Use [GitHub Discussions](https://github.com/solsebb/donutbrowser/discussions) for general questions and follow the process in [SECURITY.md](SECURITY.md) for coordinated disclosure.

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.
