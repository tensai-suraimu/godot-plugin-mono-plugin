# Mono Plugin

## Usage:

1. Download this plugin into your project and enable it.
2. Create a `.mono_repo` directory under your plugin directory.
3. Use `Project > Tools > Export Plugins` to exports them.

## Project structure reference::

```
# res://addons/
|   ...
|
|   mono_plugin/
|   |   ...
|
|   your_plugin/
|   |   .mono_repo/ # <- Exported files are stored here.
|   |   *   .git/
|   |   *   addons/
|   |   *   *   your_plugin/
|   |   *   *   *   ...folders/
|   |   *   *   *   .gitignore
|   |   *   *   *   plugin.cfg
|   |   *   *   *   ...files
|   |   *   docs/
|   |   *   ReadMe.md
|   |   *   ...documents.md
|   |
|   |   docs/
|   |   ...folders/
|   |   .gitignore
|   |   plugin.cfg
|   |   ReadMe.md
|   |   ...documents.md
|   |   ...files
|
|   your_plugin/
|   |   .mono_repo/
|   |   *    ...
|   |   ...
...
```

## TODO List

- [ ] Git integration.
- [x] Configuable directory structure.
