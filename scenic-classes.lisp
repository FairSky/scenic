
(in-package :scenic)

(declaim (optimize (debug 3)))

(defgeneric measure (object available-width available-height))

(defgeneric layout (object left top width height))

(defgeneric paint (object))

(defgeneric after-paint (object))

(defgeneric paint-order-walk (object callback &key after-callback))

(defgeneric in-widget (x y widget))

(defgeneric add-event-handler (object event propagation callback))

(defgeneric on-event (object event event-args propagation))

(defgeneric intersect (object1 object2))

;;; EVENTFUL class.

(defclass eventful ()
  ((event-handlers :accessor event-handlers :initarg event-handlers :initform nil)))

(defmethod add-event-handler ((object eventful) event propagation handler)
  (let ((handler-list (assoc event (event-handlers object))))
    (if handler-list
        (push (cons handler propagation) (cdr handler-list))
        (let ((fresh-handler-list (list (cons handler propagation))))
          (push (cons event fresh-handler-list) (event-handlers object))))))

(defmethod on-event ((object eventful) event event-arg propagation)
  (dolist (handler (cdr (assoc event (event-handlers object))))
    (when (or (null propagation) (eq (cdr handler) propagation))
      (funcall (car handler) object event-arg)
      (when (handled event-arg)
        (return-from on-event)))))

;;; WIDGET class.

(defclass widget (eventful)
  ((measured-width :accessor measured-width :initarg measured-width :initform nil)
   (measured-height :accessor measured-height :initarg measured-height :initform nil)
   (layout-left :accessor layout-left :initarg :layout-left :initform 0)
   (layout-top :accessor layout-top :initarg :layout-top :initform 0)
   (layout-width :accessor layout-width :initarg :layout-width :initform nil)
   (layout-height :accessor layout-height :initarg :layout-height :initform nil)
   (parent :accessor parent :initarg :parent :initform nil)
   (paint-order-number :accessor paint-order-number :initarg :paint-order-number :initform -1)))

(defmethod print-object ((object widget) stream)
  (format stream
          "~a (~a,~a,~a,~a)"
          (type-of object)
          (layout-left object)
          (layout-top object)
          (layout-width object)
          (layout-height object)))

(defun in-rectangle (x y left top width height)
  (and (<= left x)
       (< x (+ left width))
       (<= top y)
       (< y (+ top height))))

(defmethod in-widget (x y (widget widget))
  (in-rectangle x y
                (layout-left widget) (layout-top widget)
                (layout-width widget) (layout-height widget)))

(defun set-measured (widget available-width available-height)
  (setf (measured-width widget) available-width)
  (setf (measured-height widget) available-height)
  (values available-width available-height))

(defmethod measure ((object widget) available-width available-height)
  (set-measured object available-width available-height))

(defun set-layout (widget left top width height)
  (setf (layout-left widget) left)
  (setf (layout-top widget) top)
  (setf (layout-width widget) width)
  (setf (layout-height widget) height)
  (values))

(defmethod layout ((object widget) left top width height)
  (set-layout object left top width height))

(defmethod paint ((object widget)))

(defmethod after-paint ((object widget)))

(defmethod paint-order-walk ((object widget) callback &key (after-callback nil))
  (funcall callback object)
  (when after-callback
    (funcall after-callback object)))

;;; PLACEHOLDER class.

(defclass placeholder (widget)
  ((width :accessor width :initarg :width :initform 0)
   (height :accessor height :initarg :height :initform 0)))

(defmethod measure ((object placeholder) available-width available-height)
  (set-measured object
                (min (width object) available-width)
                (min (height object) available-height)))

;;; FILLER class.

(defclass filler (widget)
  ())

;;; TEXTATTR class.
(defclass textattr ()
  ((font-face :accessor font-face :initarg :font-face :initform "Arial")
   (font-size :accessor font-size :initarg :font-size :initform 12)
   (font-color :accessor font-color :initarg :font-color :initform (list 0.0 0.0 0.0))
   (font-slant :accessor font-slant :initarg :font-slant :initform :normal)
   (font-weight :accessor font-weight :initarg :font-weight :initform :normal)))

(defmacro copyslots (source dest &rest slots)
  `(progn
     ,@(loop
          for slot in slots
          collect `(setf (,slot ,dest) (,slot ,source)))))

(defun copy-textattr (source dest)
  (copyslots source dest font-face font-size font-color font-slant font-weight))

;;; LABEL class.

(defclass label (widget textattr)
  ((text :accessor text :initarg :text :initform "")))

(defmethod measure ((object label) available-width available-height)
  (cl-cairo2:set-font-size (font-size object))
  (cl-cairo2:select-font-face (font-face object)
                              (font-slant object)
                              (font-weight object))
  (multiple-value-bind
        (x_bearing y_bearing width height x_advance y_advance) (cl-cairo2:text-extents
                                                                (text object))
    (declare (ignore x_bearing y_bearing x_advance y_advance height))
    (let* ((extents (cl-cairo2:get-font-extents))
           (ascent (cl-cairo2:font-ascent extents)))
      (set-measured object
                    (min width available-width)
                    (min ascent available-height)))))

(defmethod layout ((object label) left top width height)
  (set-layout object left top (measured-width object) (measured-height object)))

(defmethod paint ((object label))
  (cl-cairo2:set-font-size (font-size object))
  (cl-cairo2:select-font-face (font-face object)
                              (font-slant object)
                              (font-weight object))
  (apply #'cl-cairo2:set-source-rgb (font-color object))
  (let* ((extents (cl-cairo2:get-font-extents))
         (ascent (cl-cairo2:font-ascent extents))
         (descent (cl-cairo2:font-descent extents)))
    (cl-cairo2:move-to (layout-left object) (- (+ (layout-top object) ascent 0.5) descent))
    (cl-cairo2:show-text (text object))))

;;; ORIENTABLE class.

;;; This class has only one slot, orientation, which can be either
;;; :horizontal or :vertical.

(defclass orientable ()
  ((orientation :accessor orientation :initarg :orientation :initform nil)))

;;; IMAGE class.

(defclass image (widget)
  ((image-surface :accessor image-surface :initarg :image-surface :initform nil)))

(defmethod paint ((instance image))
  (cl-cairo2:set-source-surface (image-surface instance)
                                (layout-left instance) (layout-top instance))
  (cl-cairo2:rectangle (layout-left instance) (layout-top instance)
                       (layout-width instance) (layout-height instance))
  (cl-cairo2:clip)
  (cl-cairo2:paint)
  (cl-cairo2:reset-clip))

;;; FOCUSABLE class.

(defclass focusable (eventful)
  ((has-focus :accessor has-focus :initarg :has-focus :initform nil)))

(defmethod (setf has-focus) :after (value (instance focusable))
  (if value
      (on-event instance :got-focus (make-instance 'event) nil)
      (on-event instance :lost-focus (make-instance 'event) nil)))

(defgeneric focusable (instance))

(defmethod focusable ((instance focusable))
  t)

(defmethod focusable ((instance t))
  nil)

;;; TEXTBOX class.

(defclass textbox (background textattr focusable)
  ((cursor-position :accessor cursor-position :initarg :cursor-position :initform 0)
   (selection-start :accessor selection-start :initarg :selection-start :initform nil)
   (caret-color :accessor caret-color :initarg :caret-color :initform (list 0.0 0.0 0.0))
   (selection-color :accessor selection-color
                    :initarg :selection-color
                    :initform (list 0.3 0.3 1.0))
   (text :accessor text :initarg :text :initform "")))

(defmethod initialize-instance :after ((instance textbox) &rest initargs)
  (declare (ignore initargs))
  (setf (child instance) (make-instance 'label :text (text instance)))
  (copy-textattr instance (child instance))
  (add-event-handler instance :key-down nil
                     (lambda (obj event)
                       (declare (ignore obj))
                       (print-all t
                                  "down"
                                  (key event)
                                  (modifiers event))))
  (add-event-handler instance :key-down nil
                     (lambda (obj event)
                       (declare (ignore obj))
                       (print-all t
                                  "up"
                                  (key event)
                                  (modifiers event)))))

(defmethod after-paint ((object textbox))
  ;; draw caret
  (apply #'cl-cairo2:set-source-rgb (caret-color object))
  (multiple-value-bind (x_bearing y_bearing width height x_advance y_advance)
      (cl-cairo2:text-extents (subseq (text object) 0 (cursor-position object)))
    (declare (ignore x_bearing y_bearing x_advance y_advance height))
    (let ((caret-x-pos (+ (layout-left object) width 0.5)))
      (cl-cairo2:move-to caret-x-pos (layout-top object))
      (cl-cairo2:line-to caret-x-pos (1- (+ (layout-top object) (layout-height object))))
      (cl-cairo2:stroke)))

  ;; draw selection
  )

