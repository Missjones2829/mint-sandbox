component Editor {
  connect Ui exposing { mobile, darkMode }

  connect Stores.Editor exposing {
    timestamp,
    setTitle,
    setValue,
    value,
    title,
    reset
  }

  connect Application exposing {
    isLoggedIn,
    userStatus,
    format,
    remove,
    logout,
    save,
    fork,
    page
  }

  property project : Project =
    {
      updatedAt = Time.now(),
      createdAt = Time.now(),
      content = "",
      title = "",
      userId = 0,
      id = "",
      user =
        {
          nickname = "",
          image = "",
          id = 0
        }
    }

  use Provider.Shortcuts {
    shortcuts =
      [
        {
          condition = () : Bool { true },
          action = handleFormat,
          bypassFocused = true,
          shortcut =
            [
              Html.Event:SHIFT,
              Html.Event:CTRL,
              Html.Event:S
            ]
        },
        {
          action = () { handleSave("Saved!") },
          condition = () : Bool { true },
          bypassFocused = true,
          shortcut =
            [
              Html.Event:CTRL,
              Html.Event:S
            ]
        }
      ]
  } when {
    isMine
  }

  /* Styles for the base element. */
  style base {
    box-shadow: 0 0 0.625em var(--shadow-color);
    background-color: var(--content-color);
    min-height: calc(100vh - 8em);
    border-radius: 0.5em;
    display: grid;

    if (mobile) {
      grid-template-columns: 1fr;
      grid-template-rows: 90vh 90vh;
    } else {
      grid-template-columns: 1fr 1fr;
    }
  }

  /* Styles for the toolbar. */
  style toolbar {
    border-bottom: 1px solid var(--content-border);
    background: var(--content-color);
    font-family: var(--font-family);
    color: var(--content-text);
    padding: 1em;

    grid-template-columns: 1fr auto;
    border-radius: 0.5em 0 0 0;
    align-items: center;
    grid-gap: 1em;
    display: grid;
  }

  /* Styles for the code block. */
  style code {
    border-right: 1px solid var(--content-border);
    grid-template-rows: auto 1fr;
    display: grid;

    if (mobile) {
      border-bottom: 1px solid var(--content-border);
      border-right: 0;
    }
  }

  /* Styles for the preview. */
  style preview {
    display: grid;
  }

  /* Styles for the iframe. */
  style iframe {
    border-radius: 0 0.5em 0.5em 0;
    background: white;
    height: 100%;
    width: 100%;
    border: 0;

    @media (max-width: 900px) {
      min-height: 50vh;
    }
  }

  /* Style for the toolbar hint. */
  style hint {
    white-space: nowrap;
    font-weight: 600;
    font-size: 14px;

    align-items: center;
    display: flex;

    margin-right: 10px;
    opacity: 0.75;

    svg {
      fill: currentColor;
      margin-right: 6px;
    }
  }

  /* Style for the sandbox title. */
  style title {
    background: transparent;
    font-family: inherit;
    font-weight: 600;
    font-size: 18px;
    width: 100%;
    border: 0;
    flex: 1;
  }

  /* Handles saving of the sandbox with a notification. */
  fun handleSave (notification : String) : Promise(Never, Void) {
    sequence {
      save(
        project.id,
        Maybe.withDefault(project.content, value),
        Maybe.withDefault(project.title, title))

      reset()
      Ui.Notifications.notifyDefault(<{ notification }>)
    }
  }

  /* Handles the formatting of the sandbox. */
  fun handleFormat : Promise(Never, Void) {
    sequence {
      save(
        project.id,
        Maybe.withDefault(project.content, value),
        Maybe.withDefault(project.title, title))

      format(project.id)
      reset()
      Ui.Notifications.notifyDefault(<{ "Formatted!" }>)
    }
  }

  /* Handles the deletion of the sandbox. */
  fun handleDelete : Promise(Never, Void) {
    sequence {
      content =
        <Ui.Modal.Content
          content=<{ "Are you sure you want to delete this sandbox?" }>
          title=<{ "Are you sure?" }>
          actions=<{
            <Ui.Button
              onClick={(event : Html.Event) { Ui.Modal.cancel() }}
              label="Cancel"
              type="faded"/>

            <Ui.Button
              type="danger"
              label="Yes"
              onClick={
                (event : Html.Event) {
                  sequence {
                    Ui.Modal.hide()
                    remove(project.id)
                  }
                }
              }/>
          }>/>

      Ui.Modal.show(content)
      next {  }
    } catch {
      next {  }
    }
  }

  /* Handles opening the mobile menu. */
  fun handleMenu (event : Html.Event) : Promise(Never, Void) {
    Ui.ActionSheet.show(actions)
  }

  /* Returns wether or not the sandbox belongs to the current user. */
  get isMine : Bool {
    case (userStatus) {
      UserStatus::LoggedIn user => user.id == project.userId
      UserStatus::LoggedOut => false
      UserStatus::Initial => false
    }
  }

  /* Returns the actions for the buttons and action sheet. */
  get actions : Array(Ui.NavItem) {
    if (isMine) {
      [
        Ui.NavItem::Item(
          action = (event : Html.Event) { handleDelete() },
          iconBefore = Ui.Icons:TRASHCAN,
          iconAfter = <{  }>,
          label = "Delete"),
        Ui.NavItem::Item(
          action = (event : Html.Event) { handleFormat() },
          iconBefore = Ui.Icons:FILE_CODE,
          iconAfter = <{  }>,
          label = "Format"),
        Ui.NavItem::Item(
          action = (event : Html.Event) { handleSave("Compiled!") },
          iconBefore = Ui.Icons:PLAY,
          iconAfter = <{  }>,
          label = "Compile")
      ]
    } else if (isLoggedIn) {
      [
        Ui.NavItem::Item(
          action = (event : Html.Event) { fork(project.id) },
          iconBefore = Ui.Icons:GIT_BRANCH,
          iconAfter = <{  }>,
          label = "Fork")
      ]
    } else {
      [
        Ui.NavItem::Item(
          label = "Log in to fork this sandbox.",
          iconBefore = Ui.Icons:GIT_BRANCH,
          action = Promise.never1,
          iconAfter = <{  }>)
      ]
    }
  }

  /* Renders the component. */
  fun render : Html {
    <div::base>
      <div::code>
        <div::toolbar>
          if (isMine) {
            <Ui.Input
              value={Maybe.withDefault(project.title, title)}
              onBlur={() { handleSave("Name updated!") }}
              onChange={setTitle}/>
          } else {
            <div::title>
              <{ Maybe.withDefault(project.title, title) }>
            </div>
          }

          <Ui.Row gap={Ui.Size::Px(6)}>
            if (mobile) {
              <Ui.Icon
                icon={Ui.Icons:THREE_BARS}
                size={Ui.Size::Em(2)}
                onClick={handleMenu}
                interactive={true}/>
            } else if (isMine) {
              <>
                for (item of actions) {
                  case (item) {
                    Ui.NavItem::Item action iconBefore label =>
                      <Ui.Button
                        iconBefore={iconBefore}
                        onClick={action}
                        label={label}
                        type={
                          if (label == "Delete") {
                            "danger"
                          } else {
                            "faded"
                          }
                        }/>

                    => <></>
                  }
                }
              </>
            } else {
              <>
                if (!isLoggedIn) {
                  <span::hint>
                    <Ui.Icon icon={Ui.Icons:INFO}/>
                    "Log in to fork this sandbox."
                  </span>
                }

                <Ui.Button
                  onClick={(event : Html.Event) { fork(project.id) }}
                  disabled={!isLoggedIn}
                  iconBefore={Ui.Icons:REPO_FORKED}
                  ellipsis={false}
                  label="Fork"/>
              </>
            }
          </Ui.Row>
        </div>

        <CodeMirror
          value={Maybe.withDefault(project.content, value)}
          readOnly={!isLoggedIn}
          onChange={setValue}
          mode="mint"
          javascripts=[
            @asset(../../assets/codemirror.min.js),
            @asset(../../assets/codemirror.simple-mode.js),
            @asset(../../assets/codemirror.mint.js)
          ]
          styles=[
            @asset(../../assets/codemirror.min.css),
            @asset(../../assets/codemirror.light.css),
            @asset(../../assets/codemirror.dark.css)
          ]
          theme={
            if (darkMode) {
              "dark"
            } else {
              "light"
            }
          }/>
      </div>

      <div::preview>
        <iframe::iframe src="#{@ENDPOINT}/sandbox/#{project.id}/preview?timestamp=#{timestamp}"/>
      </div>
    </div>
  }
}
