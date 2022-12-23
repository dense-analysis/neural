# ⚡ Neural

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white) ![Lua](https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white)  

Neural is a plugin for Neovim that provides blazingly fast AI code completion and productivity enhancements. 
It uses OpenAI's GPT-3 API capabilities under the hood to query for code edits and completions.

## Features
### ⚡ Fast completion
Experience lightning-fast code completion with asynchronous streaming from OpenAI's API endpoints that support it.

### 🥷 Swift Context
Become a coding ninja with `CTRL+N` to complete code without needing to specify prompt instructions.

### 💡 More than code
Edit any kind of text document. It can be used to generate function docstrings, fix comments spelling/grammar mistakes, generate ideas and more [examples from OpenAI](https://beta.openai.com/examples). 

## 🔌 Dependencies
- [curl](https://curl.se/) - for making HTTP requests
- [OpenAI API](https://beta.openai.com/) - for edits/completions querying
- [significant.nvim](https://github.com/ElPiloto/significant.nvim) (**optional**, for UI support)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) (**optional**, for animated signs)

## 🪄 Installation
You will need to obtain an [OpenAI API key](https://beta.openai.com/signup/).

### Manual
You can clone this repository to a neovim runtime path:
```
git clone -C ~/.local/share/nvim/site/pack/git-plugins/start/neural https://github.com/dense-analysis/neural.git
```

Then you will need to add `require('neural').setup({})` in your init.vim, passing a minimal configuration
```
require('neural').setup({
	open_ai = {
		api_key = '<YOUR OPENAI API SECRET KEY>'
	}
}
```

### Vim Plug
To install Neural using [vim-plug](https://github.com/junegunn/vim-plug), add the following to your `init.vim`:
```
Plug 'dense-analysis/neural'
	Plug 'muniftanjim/nui.nvim'
	Plug 'elpiloto/significant.nvim'
```
Then run `:PlugInstall` in Neovim to install Neural.

(NOTE: Not tested yet but should work)

### Packer.nvim
You can use [packer.nvim](https://github.com/wbthomason/packer.nvim) with something like:
```
use({
	'dense-analysis/neural',
	config = function()
		require('neural').setup({
			open_ai = {
		        api_key = '<YOUR OPENAI API SECRET KEY>'
		    }
		})
	end,
	requires = {
		'MunifTanjim/nui.nvim'
		'ElPiloto/significant.nvim'
	}
})
```
(NOTE: Not tested yet but should work)

## 🚀 Usage
### Prompt
You can bring the prompt by pressing `CTRL+SPACE` or the reconfigured keybinding in normal, insert, or visual mode. This will bring up a prompt where you can enter your query.

### Selection + Prompt
Visually select some code on a buffer to provide context for code editing, and then bring the prompt with `CTRL+SPACE` or the reconfigured keybinding. This will edit the code selection guided by the prompt.

### Commands
#### Code completion
For example, to use Neural for code completion, you can type `:NeuralCode intelli` in normal mode, or press the configured keybinding in insert or visual mode and enter `intelli` at the prompt.

#### Text completion
To use Neural for text generation, you can type `:NeuralText "The quick brown fox"` in normal mode, or press the configured keybinding in insert or visual mode and enter `"The quick brown fox"` at the prompt.

### Custom prompt shortcuts
You can use the `:NeuralCode` and `:NeuralText` commands to specify your query as the arguments. 

#### Add documentation
```
vnoremap <leader><leader>d :NeuralCode add documentation<CR>
```

#### Fix spelling/grammar/tone
```
vnoremap <leader><leader>s :NeuralText Fix spelling and grammar and rephrase in a proffesional tone<CR>
```

## ⚙️  Configuration
You can customize various options, such as the keybindings, highlight colors, icon and more. 

### Minimal Example
You **must** pass your OpenAI API secret key into the setup in order to query the Open AI API.

```
require('neural').setup({
	open_ai = {
		api_key = '<YOUR OPENAI API SECRET KEY>'
	}
}
```

### Full Example
Example of a default configuration:
```
{
    mappings = {
        swift = '<C-n>', -- Context completion
        prompt = '<C-space>', -- Open prompt
    },
    -- OpenAI settings
    open_ai = {
        temperature = 0.1,
        presence_penalty = 0.5,
        frequency_penalty = 0.5,
        max_tokens = 2048,
        context_lines = 16, -- Surrounding lines for swift completion
        api_key = '<YOUR OPENAI API SECRET KEY>', -- (DO NOT COMMIT)
    },
    -- Visual settings
    ui = {
        use_prompt = true, -- Use visual floating Input
        use_animated_sign = true, -- Use animated sign mark
        show_hl = true,
        show_icon = true,
        icon = '🗲', -- Prompt/Static sign icon
        icon_color = '#ffe030', -- Sign icon color
        hl_color = '#4D4839', -- Line highlighting on output
        prompt_border_color = '#E5C07B',
    },
}
```

## 📜 Acknowledgements
Neural was created by [Anexon](https://github.com/Angelchev).

I would like to extend gratitude to the following notable individuals:

- [w0rp](https://github.com/w0rp) for providing guidance and golden nuggets from invaluable experience creating & maintaining [ALE](https://github.com/dense-analysis/ale).
- [Munif Tanjim](https://github.com/MunifTanjim/) for creating an awesome UI component library - [nui.nvim](https://github.com/MunifTanjim/nui.nvim).
- [Luis Poloto](https://github.com/ElPiloto) for creating an underrated sign animations plugin [significant.nvim](https://github.com/ElPiloto/significant.nvim).

## 📙 License
Neural is released under the MIT license. See [LICENSE](https://github.com/dense-analysis/neural/blob/master/LICENSE.md) for more information.
