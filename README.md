# GitHub Scanner

```
        __                                     
  ___ _/ /  _______ _______ ____  ___  ___ ____
 / _ `/ _ \/___(_-</ __/ _ `/ _ \/ _ \/ -_) __/
 \_, /_//_/   /___/\__/\_,_/_//_/_//_/\__/_/   
/___/                                          

:: https://github.com/renatoathaydes/gh-scanner ::

```

A CLI application that makes it easy to find information about users and repositories on GitHub.

## Install

Currently, you must [install Dart](https://dart.dev/get-dart) to use gh-scanner.

With Dart installed, simply run:

```bash
pub global activate gh-scanner
```

> Make sure that `$HOME/.pub-cache/bin` (Mac/Linux) or `%APPDATA%\Pub\Cache\bin` (Windows) is on the
> `PATH`, as explained in the [pub](https://dart.dev/tools/pub/cmd/pub-global) documentation, otherwise
> you won't be able to run `gh-scanner` without using the full path to its executable.

## How to use

Run gh-scanner:

```bash
gh-scanner
```

This will start up the CLI (command-line interface) which will ask you what you want to do.

The prompt looks like this: `>>` and that's where you enter your answers.

For example, this is the top menu:

```
Enter the number for the option you want to use:

  1 - lookup user by username.
  2 - find users matching certain parameters.
  3 - find repositories for a certain topic.
>>
```

Hence, to look up a user by username, you enter `1`:

```
>> 1
What 'username' do you want to look up?
>> 
```

When no options are given, as in this menu, you just answer the question... in this case, by entering a username:

```
>> torvalds
  User - torvalds
  Name - Linus Torvalds
  Email - ?
  URL - https://github.com/torvalds
  Biography - ?
  Repositories - 6
  Followers - 99112
  Location - Portland, OR
  Hireable - ?

Show user's:
  1 - repositories
  2 - subscriptions
>> 
```

Now, you can type `1` or `2` to see the user's repositories or subscriptions, respectively.

To go back to a previous menu, you can enter `\b` (or `\back`) anywhere.

`\b` is an example of a special command, as explained below.

## Special commands

From any menu, you can enter the following special commands:

```
  \q, \quit   - quit gh-scanner.
  \t, \top    - go to the top menu.
  \b, \back   - go back to previous menu.
  \i, \login  - login to GitHub.
  \o, \logout - logout from GitHub.
  \?, \help   - show this help message.
```

For example, to see the help message, just enter `\?` or `\help` in the prompt.

## Increase your rate-limit by logging in

The `\i` (or `\login`) command allows you to login to GitHub using your default browser.

Once you've logged in, gh-scanner will receive an OAuth access token that gives it no privileges whatsoever other than
telling GitHub who is accessing its API (which gh-scanner is doing on your behalf), which lets you run many more 
queries than if you didn't login.

gh-scanner does not store the access token for security reasons, so you need to run `\login` every time you restart
gh-scanner (but if you're already logged in on your browser, just running this command is all you need to do). 

You don't need to login to use gh-scanner. But if you run a lot of queries, you will start seeing rate-limit errors
like this:

```
Unexpected response: statusCode=403, error={
  "message":"API rate limit exceeded for <IP-ADDRESS>. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)",
  "documentation_url":"https://developer.github.com/v3/#rate-limiting"
}
```

After logging in, as your rate-limit increases a lot, you should be able to run a lot more queries before seeing this
error again.

If even after logging in you still see this error, you may need to wait a few minutes to start using gh-scanner again.
