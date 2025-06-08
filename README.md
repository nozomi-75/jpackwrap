# jpackwrap

Cross-platform standalone PowerShell wrapper to build and package Maven-based Java apps using `jpackage`. It simplifies the creation of native installers for Java applications.

## 📦 Features

- Automatically detects OS: Windows, Linux, or macOS
- Parses your `pom.xml` to extract project name and version
- Builds your project using Maven
- Finds the uber JAR created by Maven Assembly
- Uses `jpackage` to create native installable packages
- Supports icons, license files, and output locations
- Works entirely from command line

## 🚀 Requirements

- PowerShell Core (Windows, Linux, macOS)
- Java JDK 14 or higher (for `jpackage`)
- Maven installed and in your `PATH`
- A Maven project with Maven Shade/Assembly

## 📄 Usage

```powershell
.\jpackwrap.ps1 -MainClass <fully.qualified.MainClass> [options]
```

**Required**

- `-MainClass`
  Fully qualified name of your application's main class (e.g. `com.example.MainApp`)

**Optional**

- `-LicenseFile`
  Path to your license file. Default: `LICENSE`

- `-IconPrefix`
  Base filename (no extension) for your app icon. Should be located in `src/main/resources/icons/`.

- `-OutputDir`
  Path where the installer will be placed. Default: current directory (`.`)

## 🐛 Troubleshooting

- **Maven not found:** Make sure `mvn` is in your system's `PATH`.
- **jpackage not found:** Ensure you're using a JDK 14+ and that `jpackage` is available in your `PATH`.
- **No fat JAR:** Ensure your project uses the Maven Shade/Assembly plugin to produce a `*-jar-with-dependencies.jar`.