Hello,

-- Update to repository: 9/10/2025

Originally this was a repository for just win32 GDI examples in Odin, however, as I used more win32, I needed a place to put more
learning examples, and decided to repose this into a more general win32 odin examples repo

The GDI examples still remain, and now there is a few more.

-- End of Update to repository: 9/10/2025

All examples (unless specifically specified in the file) can be built and run using:

odin run .

Please keep in mind this repository was being used as a learning dump for me to put finished examples in; meaning things I was learning
are then placed in this repo not the actual learning process.

It is not meant to be a tutorial repository, but can be if you're willing to put in the work to study the code and take notes.
This code is not guarenteed to be the best or most performant approach for these tasks. That is by design; I am trying to figure how how GDI works,

There is a game in here: GdiJankSnake -- but calling it a game is a stretch. More like the makings of a snake game, but very rough, buggy and very jank.
I found it a fun learning project but don't intend of fully fleshing it out.

The main resource used for figuring out how Win32 works are:
- the win32 API official documentation: https://learn.microsoft.com/en-us/windows/win32/
- Odin language windows source code
- AI Tools

Win32 API Official Documentation is really the best place to check for argument explinations. A more simplier explination can be found with AI Tools.
The Odin bindings for win32 really show how it's implimented in Odin. I recommend just copying the procedure and just slotting in what's needed.
You will see almost all procedures in this code use named arguments, that is why. I just copy/paste, slot in where and what needed

For studying C examples; I use AI tools like Copilot and PHIND. I find the odin generation from AI Tools to be incorrect at best and syntatically wrong most of the time.
So I have them generate C examples and translate that into Odin myself -- suprisingly easy and worth the effort for learning.
