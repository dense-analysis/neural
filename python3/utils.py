import sys
import json

import tiktoken

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

    # TODO: Read config
    # model = input_data["model"]

    # Count tokens
    count = count_tokens(input_data["text"])
    print(count)

    # sys.exit(count)
