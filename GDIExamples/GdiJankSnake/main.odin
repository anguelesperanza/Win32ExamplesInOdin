package maing

import "core:fmt"
import win "core:sys/windows"
import "base:runtime"
import "core:time"
import "core:math/rand"


/*
	This game is snake;
	The goal, collect an 'apple' (red square)
	and not hit yourself

	Features:
		Arrow Keys to move up/down/left/right
		Text Displaying how many apples eaten
		Snake wraps around screen borders
		Apple randomnly spawns on empty space
*/


// Globals
running := true // Exiting main loop (which in turn leads to exiting application)
apples_eaten:int

// window size
rect:win.RECT = {left = 0, top = 0, right = 600, bottom = 600}

device_context:win.HDC
memory_device_context:win.HDC
window:win.HWND

MovementEnum :: enum {
	STOP,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

// Snake 
Snake :: struct {
	size: int,
	head:win.RECT,
	tail:win.RECT,
	head_brush:win.HBRUSH,
	head_pos: [2]int,
	last_pos: [2]int,
	tail_count:int,
	head_color: win.COLORREF,
	tail_color: win.COLORREF,
	tail_brush:win.HBRUSH,
	hbitmap:win.HBITMAP,
	direction:MovementEnum,
}
snake:Snake // Create a new snake before we start the event

Tail :: struct {
	size:int,
	tail:win.RECT,
	brush:win.HBRUSH,
	pos:[2]int,
	color:win.COLORREF,
}

// Leaving this out of Tail struct as I don't want to deal with arrays inside structs
snake_tails:[dynamic]Tail
tail_last_pos: [2]int // Not in Tail struct as this is used for all tails, not a specific one
apple_spawn_on_tail:bool

// Apple
Apple :: struct {
	size: int,
	pos: [2]int,
	color: win.COLORREF,
	apple:win.RECT,
	brush:win.HBRUSH,
}
apple:Apple
apple_spawn_attempt:int // how many times the game will attempt to spawn an apple before giving up


// Callback function for handling events
window_event_proc :: proc "stdcall" (
	window: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()

	switch message {
		case win.WM_SIZE:
			win.OutputDebugStringW(win.L("WM_SIZE\n"))
		case win.WM_DESTROY:
			running = false
		case win.WM_ACTIVATEAPP:
			win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
		case win.WM_CREATE:

		case win.WM_PAINT:
			// The event for painting to the window
			// There is flickering here; double buffering could have solved it but I couldn't figure that out.
			// Instead; I 'sleep' game_loop after every iteration and it stops the flickering (until the snake gets too big then it comes back)
			paint: win.PAINTSTRUCT
			hdc := win.BeginPaint(hWnd = window, lpPaint = &paint)
			x := paint.rcPaint.left
			y := paint.rcPaint.top
			width := paint.rcPaint.right - paint.rcPaint.left
			height := paint.rcPaint.bottom - paint.rcPaint.top

			win.PatBlt(hdc, x, y, width, height, win.BLACKNESS) // Drawing the background color of the window; causing flickering but without it, painting does not work right

			win.FillRect(hDC = hdc, lprc = &apple.apple, hbr = apple.brush) // Draw Apple
			for &i in snake_tails{
				win.FillRect(hDC = hdc, lprc = &i.tail, hbr = i.brush) // Draw tails
			}
			win.FillRect(hDC = hdc, lprc = &snake.head, hbr = snake.head_brush) // Draw snake head
			win.EndPaint(hWnd = window, lpPaint = &paint)


		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					running = false
			}

		case win.WM_CHAR:
			// The event for keyboard presses (like, w,a,s,d etc)
			switch(wParam) {
				case:
					key := win.GET_KEYSTATE_WPARAM(wParam = wParam)
					switch key {
						case 'w':
							fmt.println(rune(key))
							snake.direction = MovementEnum.UP
						case 'a':
							fmt.println(rune(key))
							snake.direction = MovementEnum.LEFT
						case 's':
							fmt.println(rune(key))
							snake.direction = MovementEnum.DOWN
						case 'd':
							fmt.println(rune(key))
							snake.direction = MovementEnum.RIGHT
					}
			}
	}

	return win.DefWindowProcW(window, message, wParam, lParam)
}

// If the snake eats an apple
snake_eats_apple :: proc() {
	if snake.head_pos == apple.pos {
		spawn_apple()
		apples_eaten += 1
		add_tail()
	}
}

// If the snake moves off screen, it shows up on the other side of the screen
wrap_within_window_bounds :: proc() {
	
	// the '-8' is becuase the window is actually 608 height due to win.AdjustWindowRect 
	// Top of window wraps to bottom of the window [x]
	if snake.head_pos.y < 0 {
		snake.head_pos.y = int(rect.bottom) - 8
	 }

	// Bottom of window wraps to the top of the window [x]
	if snake.head_pos.y > int(rect.bottom) {
		snake.head_pos.y = 0 - snake.size
	}
	
	// Left wraps to the right of the window [x]
	if snake.head_pos.x < 0 {
		snake.head_pos.x = int(rect.right) - 8
	}

	// Right wraps to the left of the window	
	if snake.head_pos.x > int(rect.right) {
		snake.head_pos.x = 0 - int(snake.size)
	}
}

// Spawns apple
spawn_apple :: proc() {
	// Generates a random number 'x' and 'y' between 0 and 600, where x and 'y' is +- 60 -> the '% 10' part ensures it's upper bound is 600

	// make 'apple_spawn_attemt' (so really 10) tries to spawn an apple
	// If the apple tries to spawn on a tail, keep trying
	// If the apple does not spawn on the tail then use that.
	// For simplicities sake, not checking if apple spawns on snake head -- snake gets free apple
	for i in 0..<apple_spawn_attempt{
		
		rand_x := (int(rand.int31()) % 10) * 60
		rand_y := (int(rand.int31()) % 10) * 60

		apple.pos = ({rand_x, rand_y} / 10 * 10)
		for i in snake_tails {
			if apple.pos == i.pos {
				apple_spawn_on_tail = true
			}
		}


		if apple_spawn_on_tail == false {
			apple.apple = {left = i32(apple.pos.x), top = i32(apple.pos.y), right = i32(apple.size) + i32(apple.pos.x), bottom = i32(apple.size) + i32(apple.pos.y)}
			apple_spawn_on_tail = false
			break
		} else {
			fmt.println("Could not spawn apple; snake wins")
		}
	}	
	fmt.println(apple.apple)
	
}

add_tail :: proc() {
	tail:Tail
	tail.color = win.RGB(r = 0, g = 0, b = 255)
	tail.brush = win.CreateSolidBrush(color = tail.color)
	if len(snake_tails) == 0 {
		tail.pos = snake.last_pos
		
		tail.tail = {left = 0 + i32(tail.pos.x), top = 0 + i32(tail.pos.y), right = i32(snake.size) + i32(tail.pos.x), bottom = i32(snake.size) + i32(tail.pos.y)}
		tail_last_pos = tail.pos	
	}

	
	append(&snake_tails, tail)
	snake.tail_count += 1		
}

move_tail :: proc() {
	for i in 0..< len(snake_tails){
		if i == 0 {
			snake_tails[i].pos = snake.last_pos
		
			snake_tails[i].tail = {
				left = 0 + i32(snake_tails[i].pos.x),
				top = 0 + i32(snake_tails[i].pos.y),
				right = i32(snake.size) + i32(snake_tails[i].pos.x),
				bottom = i32(snake.size) + i32(snake_tails[i].pos.y)
			}
			
			tail_last_pos = snake_tails[i].pos	
		} else {
			temp := snake_tails[i].pos
			snake_tails[i].pos = tail_last_pos
			snake_tails[i].tail = {
				left = 0 + i32(snake_tails[i].pos.x),
				top = 0 + i32(snake_tails[i].pos.y),
				right = i32(snake.size) + i32(snake_tails[i].pos.x),
				bottom = i32(snake.size) + i32(snake_tails[i].pos.y)
			}
			tail_last_pos = temp	
		}
	}
}

snake_eats_tail :: proc() {
	for i in snake_tails {
		if snake.head_pos == i.pos {
			snake.direction = MovementEnum.STOP
		}
	} 
}

game_loop :: proc() {
	snake.last_pos = snake.head_pos
	switch snake.direction {
		case .STOP:
		case .UP:
			snake.head_pos.y -= snake.size
		case .LEFT:
			snake.head_pos.x -= snake.size
		case .DOWN:
			snake.head_pos.y += snake.size
		case .RIGHT:
			snake.head_pos.x += snake.size
	}
	snake.head = {left = i32(snake.head_pos.x), top = i32(snake.head_pos.y), right = i32(snake.size) + i32(snake.head_pos.x), bottom = i32(snake.size) + i32(snake.head_pos.y)}
	// stay_within_window_bounds()
	wrap_within_window_bounds()
	snake_eats_tail()
	snake_eats_apple()
	move_tail()
	time.sleep(time.Second / 10)

}

main :: proc() {

	// Window Creation Start
	instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance
	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = instance,
		lpszClassName = win.L("BSGWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class
	win.AdjustWindowRect(lpRect = &rect, dwStyle = win.WS_OVERLAPPEDWINDOW, bMenu = win.FALSE) // Adjust window

	// Create window
	window = win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("GDI Jank Snake"),
		dwStyle = win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE | win.WS_SYSMENU,
		X = win.CW_USEDEFAULT,
		Y = win.CW_USEDEFAULT,
		nWidth = rect.right - rect.left,
		nHeight = rect.bottom - rect.top,
		hWndParent = nil,
		hMenu = nil,
		hInstance = instance,
		lpParam = nil,
	)
	// Window Creation End

	// Creating Snake
	snake = {
		size = 60,
		head_pos = {0,0},
		last_pos = {0,0},
	}
	snake.head_color = win.RGB(r = 0, g = 255, b = 0)
	
	snake.head = {left = 0 + i32(snake.head_pos.x), top = 0 + i32(snake.head_pos.y), right = i32(snake.size) + i32(snake.head_pos.x), bottom = i32(snake.size) + i32(snake.head_pos.y)}
	snake.head_brush = win.CreateSolidBrush(color = snake.head_color)

	apple.size = 60
	apple.color = win.RGB(r = 255, g = 0, b = 0)
	apple.brush =  win.CreateSolidBrush(color = apple.color)
	apple_spawn_attempt = 30

	// End of creating snake


	spawn_apple() // spawn initiall apple
	// message/event loop -- Game Loop as well
	message:win.MSG
	for running {
		// Using PeekMessageW and not GetMessageW
		// Peak does not wait for a message to arrive if there is not one
		// Whereas GetMessageW does
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}else {
			game_loop()
			// Redraw the window
			win.InvalidateRect(hWnd = window, lpRect = nil, bErase = win.TRUE)
			win.UpdateWindow(hWnd = window)
		}
		
	}
}
