# ⚡ Neural

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white) [![Join the Dense Analysis Discord server](https://img.shields.io/badge/chat-Discord-5865F2?style=for-the-badge&logo=appveyor)](https://discord.gg/5zFD6pQxDk)

Neural is a plugin for Vim and Neovim that provides blazingly fast AI code
generation, editing, and completion.

It uses machine learning tools under the hood, such as OpenAI's GPT-3 API, to
generate text, code, and much more.

https://user-images.githubusercontent.com/38880939/209406364-d1ae162a-9fb3-4e15-8dbb-4890a4db1f5d.mov

## Features

### ⚡ Fast generation

Experience lightning-fast code generation and completion with asynchronous
streaming.

### 💡 More than code

Edit any kind of text document. It can be used to generate Python docstrings,
fix comments spelling/grammar mistakes, generate ideas and much more. See
[examples from OpenAI](https://beta.openai.com/examples) for a start.

## Disclaimer

All input data (including visually highlighted code and configurable context
lines of code) will be sent to third party servers in order to query the machine
learning models.

Language generation models based on the transformer architecture have shown
strong performance on a variety of natural language tasks such as summarization,
language translation and generating human-like text.

Open AI's Codex model has been fine-tuned for code generation tasks and can
generate patterns and structures of programming languages using attention
mechanisms to focus on specific parts of the input sequence.

### 🚨 Use generated code in production systems at your own risk!

Although the resulting output is usually syntactically valid, it must be
carefully evaluated for correctness. Use a linting tool such as
[ALE](https://github.com/dense-analysis/ale) to check your code for correctness.

## 🔌 Dependencies

- [Python](https://www.python.org/) - for making HTTP requests
- Third party API access, such as OpenAI
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) (**optional**, for Neovim UI support)
- [significant.nvim](https://github.com/ElPiloto/significant.nvim) (**optional**, for Neovim animated signs)

## 🪄 Installation

You will need to configure a third party machine learning tool for Neural to
interact with.

### Installation with Vim package management

In Vim 8 and NeoVim, you can install plugins easily without needing to use
any other tools. Simply clone the plugin into your `pack` directory.

#### Vim 8 on Unix

```bash
mkdir -p ~/.vim/pack/git-plugins/start
git clone --depth 1 https://github.com/dense-analysis/neural.git ~/.vim/pack/git-plugins/start/neural
```

#### NeoVim on Unix

```bash
mkdir -p ~/.local/share/nvim/site/pack/git-plugins/start
git clone --depth 1 https://github.com/dense-analysis/neural.git ~/.local/share/nvim/site/pack/git-plugins/start/neural
```

#### Vim 8 on Windows

```bash
# Run these commands in the "Git for Windows" Bash terminal
mkdir -p ~/vimfiles/pack/git-plugins/start
git clone --depth 1 https://github.com/dense-analysis/neural.git ~/vimfiles/pack/git-plugins/start/neural
```

#### Generating Vim help files

You can add the following line to your vimrc files to generate documentation
tags automatically, if you don't have something similar already, so you can use
the `:help` command to consult Neural's online documentation:

```vim
" Put these lines at the very end of your vimrc file.

" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
```

## 🪄 Configuration

### OpenAI

OpenAI is Neural's default data source.

You will need to obtain an [OpenAI API key](https://beta.openai.com/signup/).
Once you have your key, configure Neural to use that key, whether in a Vim
script or in a Lua config.

```vim
" Configure Neural like so in Vimscript
let g:neural = {
\   'source': {
\       'openai': {
\           'api_key': $OPENAI_API_KEY,
\       },
\   },
\}
```

```lua
-- Configure Neural like so in Lua
require('neural').setup({
    source = {
        openai = {
            api_key = vim.env.OPENAI_API_KEY,
        },
    },
})
```

Try typing `:NeuralPrompt say hello`, and if all goes well the machine learning
tool will say "hello" to you in the current buffer.

## 🚀 Usage

### Prompt

Prompt Neural with `:NeuralPrompt your message`, and the plugin will print the
results from the machine learning tool on the current line.

### Events

You can run an auto command after a Neural result has finished writing to the
buffer. This is useful for running linters and fixers, for example:

```vim
augroup NeuralEvents
    autocmd!
    autocmd User NeuralWritePost ALEFix!
augroup END
```

## 📜 Acknowledgements

Neural was created by [Anexon](https://github.com/Angelchev), and is maintained
by the Dense Analysis team.

Special thanks are due for the following individuals:

- [w0rp](https://github.com/w0rp) for providing guidance and golden nuggets from
  invaluable experience creating & maintaining
  [ALE](https://github.com/dense-analysis/ale).
- [Munif Tanjim](https://github.com/MunifTanjim/) for creating an awesome UI
  component library [nui.nvim](https://github.com/MunifTanjim/nui.nvim).
- [Luis Poloto](https://github.com/ElPiloto) for creating an underrated sign
  animations plugin
  [significant.nvim](https://github.com/ElPiloto/significant.nvim).

## 📙 License

Neural is released under the MIT license. See
[LICENSE](https://github.com/dense-analysis/neural/blob/master/LICENSE.md) for
more information.
