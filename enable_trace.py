import traceback
with open('backend/main.py', 'r') as f:
    code = f.read()
if 'traceback' not in code:
    code = 'import traceback\n' + code.replace('except Exception as e:', 'except Exception as e:\n    traceback.print_exc()')
    with open('backend/main.py', 'w') as f:
        f.write(code)
print('Done!')
