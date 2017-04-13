
# Browza

## Description

Very simple, yet reliable, Selenium-Webdriver3, command module.  Simple set of commands to automate your browser
without having to code.

Browza also supports and easily integrates with Ruby Gem *appmodel* which supports modeling (e.g. simplify pageObjects).

## APIs

### click(<locator>)

### createBrowser

Creates a browser

### displayed?(<locator>)

Returns true if the locator is displayed (visible).

### focusedText

Returns the text of the currently focused element.

### focusedValue

Returns the value of the currently focused element.

### highlight(<locator>)

Highlight the provided locator.

### hover(<locator>)

Mouseover the provided locator.

### isFocused(<locator>)

Returns true if the currently focused element matches the locator.

### navigate

### press(<key>)

Press the keyboard key.


### setTimeout

Sets the default explicit default timeout (30 sec.)

### addModel(<path to model file>)

Add a model specified by a file (e.g. JSON).  The model is a superset of a page object.

### setDimension(width, height)

Set/resize browser viewport.

### maximize

Maximize the browser.

### quit

Quit browser (quit & close)

### title

Get the title from the currently loaded page.

### isChrome?

Returns true, if the browser under test is Chrome.


### isTitle?(<regex>)

Returns a boolean - based on whether the current title matches the provided regEx.

### selected?(<locator>)
Returns true, if the locator is 'selected' (e.g. radio/checkbox button)

### type(<locator>, <text>)