# updateConfig

Small C++17 CLI utility to update `"userName"` and `"accessCode"` fields in one or more configuration files using safe, in-place text replacement.

It is intended for JSON (or JSON-like) config files that contain lines such as:

```json
{
  "userName": "oldUser",
  "accessCode": "OLD_CODE"
}
```

The tool:
- Creates a timestamped backup before writing.
- Locks the file during update to avoid concurrent writes.
- Writes to a temporary file and atomically renames it over the original.
- Can process multiple files in a single invocation.

## Build

The source uses C++17 and the standard library. On modern GCC/Clang, a typical build looks like:

```bash
g++ -std=c++17 -O2 -o updateConfig updateConfig.cpp
```

If your toolchain requires explicit linking of `stdc++fs` (older GCC versions), use:

```bash
g++ -std=c++17 -O2 -o updateConfig updateConfig.cpp -lstdc++fs
```

## Usage

```bash
./updateConfig <username> <access_code> <config_file_path> [<config_file_path> ...]
```

- `username`: New value for the `"userName"` field.
- `access_code`: New value for the `"accessCode"` field.
- `config_file_path`: One or more files to update.

### Examples

- Update a single file:

```bash
./updateConfig myUser ABCD-1234 /etc/myapp/config.json
```

- Update multiple files in one run:

```bash
./updateConfig myUser ABCD-1234 /etc/myapp/config.json /opt/app/conf/settings.json
```

### Expected input format

The program searches the file text (not a parsed JSON AST) and replaces the first regex-matching occurrences of:
- `"userName"\s*:\s*"..."`
- `"accessCode"\s*:\s*"..."`

This means it works on JSON and JSON-like text where these keys appear with string values. Whitespace around `:` is optional.

## Behavior and safety features

- **Backup**: Creates a backup next to the original named: `<file>.bak.<epochSeconds>`.
- **Disk space check**: Warns if disk space cannot be checked; errors if < ~1MB available in the target directory.
- **File locking**: Uses `flock(LOCK_EX)` to serialize writers on the same file.
- **Atomic write**: Writes to `<file>.tmp` then `rename()`s over the original.
- **Multi-file processing**: Processes each provided path independently and reports per-file success.

## Output and exit codes

- Prints what fields were updated per file. Warns if neither field is found.
- Exit code `0` if all files update successfully, otherwise `1`.

## Limitations

- The program performs regex-based text replacement; it does not parse JSON. If the keys are commented out, duplicated, or embedded in strings, results may vary.
- It only updates existing `"userName"` and `"accessCode"` keys. It does not insert them if missing.
- Only string literal values are supported by the regex.

## Implementation notes (for maintainers)

- Key functions:
  - `createBackup(path)`: copies `path` to `path.bak.<epoch>` using `std::filesystem::copy_file`.
  - `checkDiskSpace(path)`: requires ~1MB free in the parent directory.
  - `updateConfigFile(path, username, access_code)`: locks, reads, updates via regex, writes to temp, atomic rename.
- Regex used:
  - `"userName"\s*:\s*"([^"]*)"`
  - `"accessCode"\s*:\s*"([^"]*)"`
- Temporary file suffix: `.tmp`


