import os
import sys
import json

sys.path.append('./deps/tiktoken')
#
# # import tiktoken
# from .deps import tiktoken

# script_dir = os.path.dirname(os.path.realpath(__file__))
# parent_dir = os.path.dirname(script_dir)
# deps_path = os.path.join(parent_dir, 'deps')
# sys.path.append(deps_path)


# Calculate the absolute path to the 'deps' directory
# /home/user/.config/nvim/projects/neural/python3
script_dir = os.path.dirname(os.path.realpath(__file__))

# /home/user/.config/nvim/projects/neural/python2/deps
tiktoken_dir = os.path.abspath(os.path.join(script_dir, 'deps/tiktoken'))
regex_dir = os.path.abspath(os.path.join(script_dir, 'deps/mrab-regex'))
regex_dir2 = os.path.abspath(os.path.join(script_dir, 'deps/mrab-regex/regex_3'))

# Add 'deps' directory to sys.path if it's not already there
if tiktoken_dir not in sys.path:
    sys.path.insert(0, tiktoken_dir)

if regex_dir not in sys.path:
    sys.path.insert(0, regex_dir)
if regex_dir2 not in sys.path:
    sys.path.insert(0, regex_dir2)

# Now you can import tiktoken as if it was a top-level module
# import deps.tiktoken.tiktoken as tiktoken
# import regex
# exit(regex)
import tiktoken

# import deps.mrabregex.regex_3 as regex
# import tiktoken

# Rest of your code...

def count_tokens(text: str, model: str ="gpt-3.5-turbo") -> int:
    """
    Return the number of tokens from an input text using the appropriate
    tokeniser for the given model.
    """
    encoder = tiktoken.encoding_for_model(model)

    return len(encoder.encode(text))

if __name__ == "__main__":
    # Read input from command line
    input_data = json.loads(sys.stdin.readline())
    # input_text = sys.stdin.readline()

    model = input_data["model"]

    # Count tokens
    count = count_tokens(input_data["text"])
    print(count)

    # sys.exit(count)
