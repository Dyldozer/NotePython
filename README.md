import os
import filecmp
import difflib

# Set file types to ignore (optional)
IGNORE_EXTENSIONS = {".log", ".tmp"}

def get_all_files(directory):
    """Get a list of all files in a directory, preserving relative paths."""
    file_list = []
    for root, _, files in os.walk(directory):
        for file in files:
            if not any(file.endswith(ext) for ext in IGNORE_EXTENSIONS):  # Ignore unwanted extensions
                file_list.append(os.path.relpath(os.path.join(root, file), directory))
    return set(file_list)

def compare_files(file1, file2):
    """Compare two text files and return an HTML diff."""
    with open(file1, 'r', encoding='utf-8', errors='ignore') as f1, \
         open(file2, 'r', encoding='utf-8', errors='ignore') as f2:
        lines1 = f1.readlines()
        lines2 = f2.readlines()
    
    diff = difflib.HtmlDiff().make_file(lines1, lines2, file1, file2)
    
    return diff if lines1 != lines2 else None  # Only return if there's a difference

def compare_directories(dir1, dir2):
    """Compare two directories and generate an HTML report."""
    files1 = get_all_files(dir1)
    files2 = get_all_files(dir2)

    added_files = files2 - files1
    removed_files = files1 - files2
    common_files = files1 & files2

    modified_files = {}
    for file in common_files:
        path1 = os.path.join(dir1, file)
        path2 = os.path.join(dir2, file)

        if not filecmp.cmp(path1, path2, shallow=False):  # Check if file contents differ
            diff_html = compare_files(path1, path2)
            if diff_html:
                modified_files[file] = diff_html

    generate_html_report(added_files, removed_files, modified_files)

def generate_html_report(added, removed, modified):
    """Generate an HTML report showing differences."""
    report_path = "version_diff_report.html"
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("<html><head><title>Software Version Comparison</title></head><body>")
        f.write("<h1>Software Version Comparison</h1>")
        
        # Added files
        if added:
            f.write("<h2>Added Files</h2><ul>")
            for file in added:
                f.write(f"<li>✅ {file}</li>")
            f.write("</ul>")

        # Removed files
        if removed:
            f.write("<h2>Removed Files</h2><ul>")
            for file in removed:
                f.write(f"<li>❌ {file}</li>")
            f.write("</ul>")

        # Modified files
        if modified:
            f.write("<h2>Modified Files</h2>")
            for file, diff_html in modified.items():
                f.write(f"<h3>📝 {file}</h3>")
                f.write(diff_html)
                f.write("<hr>")

        f.write("</body></html>")

    print(f"✅ Report generated: {report_path}")

if __name__ == "__main__":
    dir1 = input("Enter path to first directory (old version): ").strip()
    dir2 = input("Enter path to second directory (new version): ").strip()

    if os.path.isdir(dir1) and os.path.isdir(dir2):
        compare_directories(dir1, dir2)
    else:
        print("❌ Error: One or both directories do not exist.")
