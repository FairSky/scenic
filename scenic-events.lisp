
(in-package :scenic)

;;; EVENT class.

(defclass event ()
  ((handled :accessor handled :initarg :handled :initform nil)
   (widget-list :accessor widget-list :initarg :widget-list :initform nil)))

;;; MOUSE-EVENT class.

(defclass mouse-event (event)
  ((mouse-x :accessor mouse-x :initarg :mouse-x :initform nil)
   (mouse-y :accessor mouse-y :initarg :mouse-y :initform nil)
   (modifiers :accessor modifiers :initarg :modifiers :initform nil)))

;;; MOUSE-MOVE-EVENT

(defclass mouse-move-event (mouse-event)
  ((mouse-rel-x :accessor mouse-rel-x :initarg :mouse-rel-x :initform nil)
   (mouse-rel-y :accessor mouse-rel-y :initarg :mouse-rel-y :initform nil)))

;;; MOUSE-BUTTON-EVENT

(defclass mouse-button-event (mouse-event)
  ((mouse-button :accessor mouse-button :initarg :mouse-button :initform nil)))

;;; KEY-EVENT class.

(defclass key-event (event)
  ((key :accessor key :initarg :key :initform nil)
   (modifiers :accessor modifiers :initarg :modifiers :initform nil)))
