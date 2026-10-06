import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    appbar_match = re.search(r'appBar:\s*AppBar\(', content)
    if not appbar_match:
        return False
        
    start_idx = appbar_match.start()
    
    # get title
    title = "Admin Page"
    title_start = content.find('title:', start_idx)
    if title_start != -1 and title_start < start_idx + 300:
        q1 = content.find("'", title_start)
        if q1 != -1:
            q2 = content.find("'", q1+1)
            title = content[q1+1:q2]

    # find closing parenthesis of AppBar
    idx = appbar_match.end() - 1 # points to '('
    open_parens = 0
    close_idx = -1
    for i in range(idx, len(content)):
        if content[i] == '(':
            open_parens += 1
        elif content[i] == ')':
            open_parens -= 1
            if open_parens == 0:
                close_idx = i
                break

    if close_idx == -1:
        return False
        
    end_idx = close_idx + 1
    while end_idx < len(content) and content[end_idx] in [' ', '\n', '\r', ',']:
        end_idx += 1
        
    content_no_appbar = content[:start_idx] + content[end_idx:]
    
    # Inject title
    body_idx = content_no_appbar.find('body:')
    if body_idx == -1:
        return False
        
    children_idx = content_no_appbar.find('children:', body_idx)
    if children_idx == -1:
        # maybe no children? let's just prepend a Column
        pass
    else:
        bracket_idx = content_no_appbar.find('[', children_idx)
        if bracket_idx != -1:
            title_block = f"""
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('{title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.textPrimary)),
                    ),"""
            new_content = content_no_appbar[:bracket_idx+1] + title_block + content_no_appbar[bracket_idx+1:]
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
            
    return False

def main():
    admin_dir = r"c:\Users\Vishw\Downloads\TNT\lib\features\admin"
    count = 0
    for root, dirs, files in os.walk(admin_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                # some files have 2 appbars? we only replace the first
                while process_file(filepath):
                    print(f"Processed {filepath}")
                    count += 1
    print(f"Total processed: {count}")

if __name__ == '__main__':
    main()
