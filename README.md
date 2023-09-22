# ⚡ Neural

[![Vim](https://img.shields.io/badge/VIM-%2311AB00.svg?style=for-the-badge&logo=vim&logoColor=white)](https://www.vim.org/) [![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/) [![CI](https://img.shields.io/github/actions/workflow/status/dense-analysis/neural/main.yml?branch=main&label=CI&logo=github&style=for-the-badge)](https://github.com/dense-analysis/neural/actions?query=event%3Apush+workflow%3ACI+branch%3Amain++) [![Join the Dense Analysis Discord server](https://img.shields.io/badge/chat-Discord-5865F2?style=for-the-badge&logo=appveyor)](https://discord.gg/5zFD6pQxDk)

A ChatGPT Vim plugin, an OpenAI Neovim plugin, and so much more! Neural integrates various machine learning tools so you can let AI write code for you in Vim/Neovim, among other helpful things.

## 🌟 Features

* Generate text easily `:Neural write a story`
* Support for multiple machine learning models
* Focused on privacy and avoiding leaking data to third parties
* Easily ask AI to explain code or paragraphs `:NeuralExplain`
* Compatible with Vim 8.0+ & Neovim 0.8+
* Supported on Linux, Mac OSX, and Windows
* Only dependency is Python 3.7+

Experience lightning-fast code generation and completion with asynchronous
streaming.

Edit any kind of text document. It can be used to generate Python docstrings,
fix comments spelling/grammar mistakes, generate ideas and much more. See
[examples from OpenAI](https://beta.openai.com/examples) for a start.

## 🔌 Plugin Integrations

If the following plugins are installed, Neural will detect them and start using
them for a better experience.

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) - for Neovim UI support
- [significant.nvim](https://github.com/ElPiloto/significant.nvim) - for Neovim animated signs
- [ALE](https://github.com/dense-analysis/ale) - For correcting problems with
  generated code

## 🪄 Installation

Add Neural to your runtime path in the usual ways.

If you have trouble reading `:help neural`, try the following.

```vim
packloadall | silent! helptags ALL
```

#### Vim `packload`:

```bash
git clone --depth 1 https://github.com/dense-analysis/neural.git ~/.vim/pack/git-plugins/start/neural
```

#### Neovim `packload`:

```bash
git clone --depth 1 https://github.com/dense-analysis/neural.git ~/.local/share/nvim/site/pack/git-plugins/start/neural
```

#### Windows `packload`:

```bash
git clone --depth 1 https://github.com/dense-analysis/neural.git ~/vimfiles/pack/git-plugins/start/neural
```

#### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'dense-analysis/neural'
    Plug 'muniftanjim/nui.nvim'
    Plug 'elpiloto/significant.nvim'
```

#### [Vundle](https://github.com/VundleVim/Vundle.vim)

```vim
Plugin 'dense-analysis/neural'
```

## 🚀 Usage

You will need to configure a third party machine learning tool for Neural to
interact with. OpenAI is Neural's default data source, and one of the easiest
to configure.

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

Try typing `:Neural say hello`, and if all goes well the machine learning
tool will say "hello" to you in the current buffer. Type `:help neural` to
see the full documentation.

## 🛠️ Commands

### `:NeuralExplain`

You can ask Neural to explain code or text by visually selecting it and running
the `:NeuralExplain` command. You may also create a custom keybind for
explaining a visual range with `<Plug>(neural_explain)`.

Neural will make basic attempts to redact lines that appear to contain passwords
or secrets. You may audit this code by reading
[`autoload/neural/redact.vim`](https://github.com/dense-analysis/neural/blob/main/autoload/neural/redact.vim)

### `:NeuralStop`

You can stop Neural from working by with the `NeuralStop` command. Unless
another keybind for `<C-c>` (CTRL+C) is defined in normal mode, Neural will run
the stop command by default when you enter that key combination. The default
keybind can be disabled by setting `g:neural.set_default_keybinds` to any falsy
value. You can set a keybind to stop Neural by mapping to `<Plug>(neural_stop)`.

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

## ℹ️ Disclaimer

All input data will be sent to third party servers in order to query the machine
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

## 📙 License

Neural is released under the MIT license. See
[LICENSE](https://github.com/dense-analysis/neural/blob/master/LICENSE.md) for
more information.
