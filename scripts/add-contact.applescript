-- Create a real macOS Contacts card (argv: name, handle).
-- The handle is added as a phone for +/digit handles, otherwise as an email.
-- First run triggers a one-time Automation prompt for Contacts.
-- Usage: osascript add-contact.applescript "Alex" "+15551234567"
on run argv
	set theName to item 1 of argv
	set theHandle to item 2 of argv
	tell application "Contacts"
		set p to make new person with properties {first name:theName}
		if theHandle starts with "+" then
			make new phone at end of phones of p with properties {label:"mobile", value:theHandle}
		else
			make new email at end of emails of p with properties {label:"home", value:theHandle}
		end if
		save
	end tell
end run
