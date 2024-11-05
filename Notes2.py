from tkinter import *

root = Tk()
root.title("Using Pack")
root.geometry("300x100")  # set starting size of window
root.config(bg="skyblue")

# Example of how to arrange Button widget using pack
button1 = Button(root, text="Click me")
button1.pack(side="left")

# Example of how to arrange Label widgets using pack
label1 = Label(root, text="Read me", bg="skyblue")
label1.pack(side="right")
label2 = Label(root, text="Hello", bg="purple")
label2.pack(side="right")

def toggled():
    '''display a message to the terminal every time the check button
    is clicked'''
    print("The check button works.")

# Example of how to arrange Checkbutton widget using pack
var = IntVar()  # Variable to check if checkbox is clicked, or not
check = Checkbutton(root, text="Click me", bg="skyblue", command=toggled, variable=var)
check.pack(side="bottom")
root.mainloop()