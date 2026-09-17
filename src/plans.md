
# Plans

## Operations to support

- Copy File       (filesystem::copy_file)
- Delete File     (os.remove)
- Create Symlink  (filesystem::create_symlink, create_directory_symlink)
- Create Hardlink (filesystem::create_hard_link)

## Queries

- File modification
- Follow symlinks (filesystem::read_symlink)
- Filter return values of walkdir

## Walking callbacks

- Skip directories
- Ignore files
