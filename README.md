# Spaceport.nvim

The "blazingly fastest" way to get to your projects

## Why

I got really annoyed with the pattern of cd'ing to a project folder then doing `nvim .` then starting to program. I wanted to just type `nvim` and then a few keystrokes later, be in a project. I wanted something that was kind of like [harpoon](https://github.com/ThePrimeagen/harpoon), but for directories, not files.

## How

Spaceport automatically keeps track of every file and directory you open neovim to. It then uses this information to provide a list of the most recently used projects. Then you can navigate to a project by selecting it from the list

## Tag System

Some projects can be tagged so that they always appear as a certain number on the list. For example, I have my neovim dotfiles as tag 1, so in a new terminal window, I can type `nvim` and then `1p` and instantly be at my dotfiles, rather than having to type `cd ~/.config/nvim<CR>nvim .`.

The tag system is something I've only seen in one other startup plugin: [startup.nvim](https://github.com/startup-nvim/startup.nvim), yet even in startup.nvim the tags have to be manually defined in your config making them really clunky to use.

The tag system when properly used can make it so that you can get to your most used projects in less than half a second.

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
{
    'CWood-sdf/spaceport.nvim',
    opts = {

    },
    lazy = false, -- load spaceport immediately
}
```

</details>

The default options are:

```lua
{

    -- This prevents the same directory from being repeated multiple times in the recents section
    -- For example, I have replaceDirs set to { {"~/projects", "_" } } so that ~/projects is not repeated a ton
    -- Note every element is applied to the directory in order,
    --   so if you have { {"~/projects", "_"} } and you also want to replace
    --   ~/projects/foo with @, then you would need
    --   { {"~/projects/foo", "@"}, {"~/projects", "_"} }
    --   or { {"~/projects", "_"}, {"_/foo", "@"} }
    replaceDirs = {},

    -- turn /home/user/ into ~/ (also works on windows for C:\Users\user\)
    replaceHome = true,

    -- What to do when entering a directory, personally I use "Oil .", but Ex is preinstalled with neovim
    projectEntry = "Ex",

    -- The farthest back in time that directories should be shown
    -- I personally use "yesterday" so that there aren't millions of directories on the screen.
    -- the possible values are: "pin", "today", "yesterday", "pastWeek", "pastMonth", and "later"
    lastViewTime = "later",

    -- The maximum number of directories to show in the recents section (0 means show all of them)
    maxRecentFiles = 0,

    -- The sections to show on the screen (see `Customization` for more info)
    sections = {
        "_global_remaps",
        "name",
        "remaps",
        "recents",
    },

    --- Set to true to have more verbose logging
    debug = false,

    -- The path to the log file
    logPath = vim.fn.stdpath("log") .. "/spaceport.log",
    -- How many hours to preserve each log entry for
    logPreserveHours = 24,

}
```

## Performance

Spaceport is designed to be as fast as possible. The config time measured with lazy.nvim is ~0.2ms with the default configuration. Each render cycle takes only about 20-40ms.

## Usage

Spaceport automatically loads after neovim has started, there is no need to run any commands, but if you want to switch projects, run `:Spaceport` to go back to the start screen.

All the remaps are visible at the top of the screen with the default configuration. Any remap that deals with a project can either be used while hovering over the project or by prefixing the command with the project's number. For example, if I have a project with the number 1, I can type `1p` to open that project, or I can move the cursor to hover over the project and press `p`.

Spaceport starts out without any history of your favorite directories, so when you're starting out, you will need to do the pattern of cd'ing to a directory and then doing `nvim .` to get it to show up in the recents section. Once you have a few directories in the recents section, you can start tagging them so that you can quickly jump to them.

This is what spaceport looks like when projects are tagged.

![image](https://github.com/CWood-sdf/spaceport.nvim/assets/98367120/f07c181b-77c7-47d0-b5a3-451f0ac869e6)

## Customization

Spaceport is completely customizable, anything displayed on the screen can be reconfigured by changing the `sections` option. The default sections are:

```lua
{
    "_global_remaps",
    "name",
    "remaps",
    "recents",
}
```

All the preconfigured sections are:

- `_global_remaps`: This section adds a few remaps that are universally useful, like being able to refresh the screen
- `name`: This section displays an ascii art "Spaceport" logo
- `remaps`: This section displays all the remaps that are defined as visible in all the other screens
- `recents`: This section displays the most recently used projects, as well as the pinned projects
- `name_blue_green`: This section displays the ascii art logo, but with a blue-green gradient
- `hacker_news`: This section displays the top 5 stories on hacker news

### Default Screen Highlight Groups

If you want to change the highlighting of the recents or remaps sections, you can set any of the following highlight groups: `SpaceportRemapDescription`, `SpaceportRemapKey`, `SpaceportRecentsTitle`, `SpaceportRecentsProject`, or `SpaceportRecentsCount`

The code to do that would look like this:

```lua
vim.api.nvim_set_hl(0, "SpaceportRecentsTitle", {
    fg = "red",
})
```

### Custom Screens

If you want to have your own section, you can add a table entry to the `sections` array. The table entry should conform to the type `SpaceportScreen` defined in `lua/spaceport/screen.lua`. An example screen could be something like this:

```lua
local i = 0
{
    title = "count",
    lines = function()
        return {
            -- lines can be strings
            "Count: ",
            -- or lines can be arrays of `SpaceportWord`s, this allows the words to have highlights
            {

                -- Spaceport words are tables with the following fields:
                -- [1] = the text to display
                -- colorOpts = the options to pass to `vim.api.nvim_set_hl`
                -- See [nvim_set_hl docs](https://neovim.io/doc/user/api.html#nvim_set_hl())

                -- Alternatively, if you want the value to be customizable, you can set the
                --   _name field to the name of a global highlight group along with all the other values
                --   If spaceport detects that the global highlight group exists, it will use that, otherwise it will create the highlight group with the given values
                {
                    i .. "",
                    colorOpts = {
                        fg = "red",
                    },
                },
            },
        }
    end,
    -- The number of empty lines to put between this section and the previous section
    topBuffer = 0,
    remaps = {
        {
            key = "w",
            mode = "n",
            --- Spaceport passes two parameters to action:
            --- 1. The line that the cursor is on (relative to the start of the screen)
            --- 2. vim.v.count
            action = function(line, count)
                i = i + 1
                -- This will cause the screen to be re-rendered
                require('spaceport.screen').render()
            end,
            description = "Increment count",
            -- Setting this to false will make the remap not be shown in the 'remaps' section
            visible = true,
            -- Setting this to false will make it so that the action will only be called when the cursor is on the lines of the screen
            callOutside = true,
        },
    },
    -- if this is nil, the screen will be centered
    position = {
        -- Positive values are from the top, negative values are from the bottom
        row = -1,
        -- Positive values are from the left, negative values are from the right
        col = 1,
    },
    onExit = function()
        -- This function will be called when spaceport is exited
        i = 0
    end,
}
```

Note that all of these values except lines can be left nil in an actual screen, this is just all filled out to show what the possible values are.

If you have a screen that may be universally useful (like a better looking version of any default screen), open a PR with that code in a file in the `lua/spaceport/screens/` directory, you can see some other files in that directory if you need examples

## Tmux Integration

If you're in a tmux window, you can call `:Spaceport renameWindow` to rename the window, furthermore this information is saved so that whenever you reopen that directory, the tmux window name will be changed.

The same thing can be done for sessions with `:Spaceport renameSession`

If you want to split the tmux window while preserving the directory you're in, you can call `:Spaceport verticalSplit` or `:Spaceport horizontalSplit`, and it will split the window vertically and open to the project dir in a new pane.

## Telescope integration

Spaceport integrates with telescope so that you can fuzzy find projects to open. To use this, you need to have telescope installed, and then you can add this to your config:

```lua
require('telescope').load_extension('spaceport')
```

Then you can use the `projects` picker to select a project by its directory name:

```lua
require('telescope').extensions.spaceport.projects()
```

Or you can search for a specific tmux window or session name:

```lua
require('telecope').extensions.spaceport.tmux_windows()

require('telecope').extensions.spaceport.tmux_sessions()
```

## Events

Spaceport emits two events:

- `SpaceportEnter`: This event is emitted when spaceport is entered
- `SpaceportDone`: This event is emitted when the project is exited, or when neovim is started with a file or directory argument

## Spaceport Buffer Name

The spaceport buffer is named `spaceport` with a filetype of `spaceport`. You can use this to set up autocommands for when spaceport is entered or exited

## Importing vim.v.oldfiles

All other plugins use the `vim.v.oldfiles` to keep track of your most recently used files, rather than your directories. To import this data, just call `:Spaceport importOldfiles` and pass the number of files you want to import as an argument. Spaceport will add them to the database as being opened today because `vim.v.oldfiles` does not provide time data.
