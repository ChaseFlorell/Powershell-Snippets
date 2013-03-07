# Sometimes you need to ask for some input from the user.
# Feel free to add as many questions as you like.

$title = "Some Title"
$message = "Ask some question that you need follow up on?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "The answer to the question is YES."
	
$maybe = New-Object System.Management.Automation.Host.ChoiceDescription "&Maybe", `
    "The answer to the question is MAYBE."
	
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "The answer to the question is NO."
	
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $maybe, $no)
$howToProcess = $host.ui.PromptForChoice($title, $message, $options, 0)

if($howToProcess -eq 0) {
    # User responded YES
}

if($howToProcess -eq 1) {
    # User responded MAYBE
}

if($howToProcess -eq 2) {
    # User responded NO
}