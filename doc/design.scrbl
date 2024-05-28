#lang scribble/manual

@require[scribble/core
         racket/runtime-path
         "ux.rkt"]

@title{Mindstream Design}

@section{Layout}

Mindstream's core functionality is moment-to-moment versioning (on @function{save-buffer}). Aside from this core functionality that can be used anywhere, we provide a few special ways to access it for which these high level concepts are of interest:

@itemlist[#:style 'ordered
  @item{Anonymous Projects}
  @item{Named Projects}
  @item{User-defined templates}
]

Anonymous projects are created at @variable{mindstream-path} from templates created by the user at @variable{mindstream-template-path}. If we feel an anonymous project is worth keeping, giving it a name saves it to @variable{mindstream-save-session-path} by default. It is likely that there will be a lot of small to medium sized projects at @variable{mindstream-save-session-path}. Larger projects are likely to reside at their own (not Mindstream-specific) path (where Mindstream's core functionality may still be used).

Within @variable{mindstream-path}, anonymous projects are filed under the name of the template from which they were created.

@codeblock{
/path/to/mindstream-anon/
  elisp/
    2024-04-18-34e577e46c96d9728ae2522cc64bc087f0d222bf
    2024-05-10-e577e46c96d9728ae2522cc64bc087f0d222bf34
  python/
    2023-12-18-73e457e46c96d7928ae2252cc46bc078fd0222fb
  racket/
    2024-05-26-435e774ec696d9728ae2522cc64bc087f0d222bf
}

@section{Changes From Initial Design}

@itemlist[#:style 'unordered
  @item{Sessions are now branches in a repo rather than (effectively) entire repos -- they can be begun anywhere, saved, loaded, merged.}
  @item{There can be more than one anonymous project active at any time per major mode (formerly just one).}
  @item{Anonymous projects are categorized by template (formerly flat).}
  @item{Saving an anonymous project moves (rather than copies) the project so that all open project buffers remain open.}
  @item{Load project is no longer provided as a feature.}
  @item{Ability to view open sessions (and without maintaining global state).}
  @item{Ability to label and annotate versions (via tags).}
  @item{More settings (change branch, merge, etc.) where completion is needed.}
]

@section{Concepts}

@definition["Project"]{A Git version-controlled folder.}

@definition["Template"]{A folder at @variable{mindstream-template-path} that serves as the initial contents of a project.}

@definition["Session"]{A sequence of states of a project starting from some initial state. Modeled by a Git branch whose name starts with @code{mindstream-} (customizable via @variable{mindstream-session-prefix}).}

@definition["Anonymous project"]{A project at @variable{mindstream-path} whose setup is abstracted by Mindstream.}

@definition["Anonymous session"]{A session beginning at the current state whose setup is abstracted by Mindstream.}

@definition["Saved session"]{A named session, any Git branch whose name begins with @code{mindstream-} and where the suffix was given by the user rather than automatically generated as part of beginning a session.}

@section{How to Interpret This Document}

We will use describe UX flows using a special "grammatical" notation. This unusual choice is actually very natural and hierarchically expresses the desired UX. Hopefully, after the initial period of becoming used to it, it will be a very efficient way to refer to and even think about and discuss the UX.

A UX will be described using a grammar like this one:

@UX[("New project"
     ("Select template"
      "Select file"
      "Begin session"))
    ("Select template"
     "Select folder by name")
    ("Begin session"
     ("Generate name"
      "Start Git branch"))]

This is equivalent to the more familiar graphical flow visualizations below.

@subsection[#:style 'unnumbered]{New project}

@(define-runtime-path img-path "assets/img/mindstream-new.drawio.svg")
@(centered (image img-path #:scale 0.7))

@subsection[#:style 'unnumbered]{Select template}

@(define-runtime-path img-path2 "assets/img/mindstream-select-template.drawio.svg")
@(centered (image img-path2 #:scale 0.7))

@subsection[#:style 'unnumbered]{Begin session}

@(define-runtime-path img-path3 "assets/img/mindstream-begin-session.drawio.svg")
@(centered (image img-path3 #:scale 0.7))

As you can see, it communicates the same information much more economically, so we will use it and see how it goes!

A few further observations on the notation:

@itemlist[#:style 'unordered
  @item{Flows are hierarchical. The first line shows the complete flow at a high level. Each subsequent row elaborates component flows at lower and lower levels. If a component is at a sufficiently low level, it is not further elaborated.}
]

@UX[("New project"
     ("Select template"
      "Select file"
      "Begin session"))
    ("Select template"
     "Select folder by name")]

@itemlist[#:style 'unordered
  @item{Flows are usually sequential. A B C means that A happens, then B happens, and then C happens.}
]
@UX[("New project"
     ("Select template"
      "Select file"
      "Begin session"))]

@itemlist[#:style 'unordered
  @item{There could be alternative flows that occur depending on conditions. In such cases, the flows are listed in order of precedence.}
]

@UX[("Enter anonymous session"
     "Visit existing session"
     "Start new session")]

@itemlist[#:style 'unordered
  @item{Flows may occur in stages. Each stage is listed on a separate line.}
]

@UX[("Load project"
     (stages ("Recall recent projects" "Recall saved projects")
             ("Choose folder")))]

@itemlist[#:style 'unordered
  @item{When a lower-level flow is shared in common by many high-level flows, instead of duplicating the shared flow we simply link to its definition.}
]

@UX[("New project"
     ("Select template"
      (link "Begin project")))]

Lastly, the notation is intentionally limited in some ways. We do not try to elaborate the implementation logic in terms of loops, variable bindings, processing of collections, and so on. The abstraction level is such that it expresses the design in ways that can be meaningfully communicated, discussed and modified, without incurring the overhead of the details of actual implementation.

@section{Flows}

Let's now comprehensively define all of Mindstream's UX flows using the above notation.

@table-of-contents[]

@subsection{High Level}

These "high level" flows are @function{interactive} and exposed to the user via keybindings in @function{mindstream-mode}.

@subsubsection{New Project From Template}

Start a new @tech{anonymous project} at @variable{mindstream-path}.

@UX[("New project"
     ((link "Choose template")
      (link "Begin project")))]

@subsubsection{Enter Anonymous Project}

Enter an @tech{anonymous project} for the current major mode, creating a new one if necessary. Being context-sensitive, this is intended to be the quickest way to enter a relevant Mindstream scratch session.

@UX[("Enter anonymous project"
     ("Identify MRU anonymous project for major mode"
      "Identify MRU file"
      (link "Open file"))
     ("Select template for major mode" (link "Begin project")))
    ("Select template for major mode"
     (link "Infer template")
     (link "Choose template"))]

@subsubsection{Open Session}

Visit an open Mindstream session.

@UX[("Open session"
     ("List projects with open sessions" (link "Choose folder path")))]

We could do this just by checking the Git branch that each open buffer is on, to avoid maintaining any global registry of sessions (which would be bug-prone).

@subsubsection{Open Anonymous Session}

Visit an open anonymous session. Choose from paths that are relative to @variable{mindstream-path}, e.g. @code{racket/2024-05-26-06b432} instead of @code{~/tmp/mindstream/racket/2024-05-26-06b432}.

@UX[("Open anonymous session"
     ("List open anonymous projects" (link "Choose relative folder")))]

@subsubsection{Open Anonymous Session for Mode}

Same as @secref["Open_Anonymous_Session"] but restricted to sessions whose major mode is the current major mode.

@subsubsection{Begin Session Here}

Start a session from the current state of the project.

@UX[("Begin session here"
     ((link "Begin session")))]

@subsubsection{Save Session}

Save the session by giving the branch a descriptive name.

@UX[("Save session"
     (link "Rename Git branch"))]

@subsubsection{Load Session}

Load a session in the current project by changing to the corresponding Git branch.

@UX[("Load session"
     ((link "Choose Git branch")))]

@subsubsection{Merge Session}

Merge a mindstream session branch into another branch in the project as a single commit.

@UX[("Merge session"
     ((link "Squash merge Git branch")))]

It may be useful to provide a version of this command that deletes the mindstream branch after successfully merging it, like @function{mindstream-merge-and-delete-session}.

@subsubsection{Save Project}

Save a project to a permanent location, defaulting to @code{mindstream-save-session-path}.

@UX[("Save project"
     ((link "Choose folder") (link "Copy folder") "Close anonymous project" (link "Open file") (link "Begin session")))
    ("Close anonymous project"
     ("Close all open buffers in project"))]

It may be wise to @emph{move} the anonymous project to its new location (instead of just copying it) so that Emacs will implicitly keep all the project buffers open. Otherwise, it would be useful to at least replicate this behavior.

@subsubsection{Load Project}

Mindstream does not provide a special feature for this, as projects are just ordinary Git repos and there are many ways to open these using existing Emacs flows, such as Projectile (@function{projectile-switch-project}) or Project.el (@function{project-switch-project}), or simply navigating to the folder using @keybinding{C-x C-f}.

@subsubsection{Tag}

Annotate the current version with a label and a description (by adding a Git tag).

@UX[("Tag"
     ("Git tag"))]

@subsubsection{Iterate}

Add all new files that aren't Gitignored and record a fresh commit. This happens every time a file is saved if the project is currently in a Mindstream session (i.e. the current branch name begins with @variable{mindstream-session-prefix}).

@UX[("Iterate"
     ("Git add all" "Git commit"))]

@subsection{Low Level}

These flows are used in various features but aren't directly exposed to the user.

@subsubsection{Begin Project}

@tech{Projects} always start @tech[#:key "anonymous project"]{anonymous}. @tech{Templates} are copied to a new folder created in @variable{mindstream-path} in a subfolder with the same name as the template, so for instance, a new Python project would be under @variable{mindstream-path}@code{/python/<unique-name>}.

@UX[("Begin project"
     ((link "Generate name")
      "Copy template"
      (link "Select starting file")
      (link "Begin session")))
    ("Copy template"
     (link "Choose folder by name")
     (link "Copy folder"))]

@subsubsection{Begin Session}

In the special case where we are beginning a session in a new @tech{anonymous project} via @secref["Begin_Project"], we use the branch name @variable{mindstream-main}. This is because most such sessions are likely to either remain anonymous or be saved at @variable{mindstream-save-session-path} purely as "streams," rather than merged into traditional branches with annotated commits, and thus the initial mindstream session branch is likely to be the "main" or even the only branch.

@UX[("Begin session"
     ((link "Generate name")
      (link "Start Git branch")))]

@subsubsection{Infer Template}

Infer a template to use for the major mode.

@UX[("Infer template"
     "Select preferred template for major mode"
     "Find template for major mode")]

@subsubsection{Choose Template}

Choose a template from @variable{mindstream-template-path} by name.

@UX[("Choose template"
     ((link "Choose folder by name")))]

@subsubsection{Select Starting File}

If there's only one file don't prompt the user.

@UX[("Select starting file"
     (link "Choose file"))]

@subsubsection{Squash Merge Git Branch}

Merge the branch into its base branch as a squashed commit, leaving the original branch commits intact.

@UX[("Squash merge Git branch"
     (stages ((or "Select unique base branch" (link "Choose base branch")))
             ("Prepare commit message")
             ("Merge into base")))]

@subsection{Primitives}

These are general purpose utilities used in the higher level flows.

@subsubsection{Choose Folder}

Choose a folder in a completion menu. The contents of the menu are @emph{relative paths to folders} at some initial path, supporting navigation including @keybinding{Tab} to enter a folder without selecting.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Choose Folder By Name}

Choose a folder by name in a completion menu. The contents of the menu are @emph{folder names} (not relative or absolute paths) at some path, and navigation to other paths or subpaths is @emph{not} supported.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Choose Folder Path}

Choose a folder by absolute path in a completion menu. The contents of the menu are @emph{absolute paths to folders}, and navigation to other paths or subpaths is @emph{not} supported.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Choose Relative Folder}

Choose a folder in a completion menu relative to a fixed base path. The contents of the menu are @emph{relative paths to folders}, and navigation to other paths or subpaths is @emph{not} supported.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Choose File}

List directory files recursively and enter completion with relative file names, without navigation.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Choose Base Branch}

Choose base branch to merge into. Show all branches in the repo.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Choose Git Branch}

Choose from all branches with names starting @code{"mindstream-"}.

This uses @secref["Completion_with_Short-Circuiting"].

@subsubsection{Copy Folder}

Copy folder to a given location.

@subsubsection{Start Git Branch}

Create a Git branch with the given name, but prefix the name with @code{"mindstream-"}.

@subsubsection{Rename Git Branch}

Rename the current branch to the given name, but prefix the name with @code{"mindstream-"}.

@subsubsection{Generate Name}

Generate a unique yet recognizable name. It should be unique so that there are no collisions with existing names, and it should include at least some identifying information such as a date to help the user have an idea of what it represents.

@subsubsection{Open File}

Visit a given file in Emacs (e.g. @function{find-file}).

@section{UI Primitives}

@subsection{Completion with Short-Circuiting}

@itemlist[#:style 'unordered
    @item{If there is only one candidate, it is selected without entering completion.}
    @item{Completion shows relevant recent selections.}
    @item{Completion supports @keybinding{M-p}.}
]
