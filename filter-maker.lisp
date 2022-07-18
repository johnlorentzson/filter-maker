(in-package #:filter-maker)

(defclass predicate ()
  ((%function :reader predicate-function :initarg :function)
   (%pretty-name :reader pretty-name :initarg :pretty-name)
   (%arguments :reader arguments :initarg :arguments)))

(defclass rule ()
  ((%predicate :accessor predicate :initarg :predicate
               :initform (first (predicates *application-frame*)))
   (%key :accessor key :initarg :key
         :initform (first (keys *application-frame*)))
   (%value :accessor value :initform "")))

(defclass key ()
  ((%function :accessor key-function :initarg :function)
   (%pretty-name :accessor pretty-name :initarg :pretty-name)))

(defmethod apply-rule ((rule rule) item)
  (if (= (arguments (predicate rule)) 2)
      (funcall (predicate-function (predicate rule))
               (funcall (key-function (key rule)) item)
               (value rule))
      (funcall (predicate-function (predicate rule))
               (funcall (key-function (key rule)) item))))

(define-application-frame filter-maker ()
  ((%predicates :accessor predicates :initarg :predicates :initform '())
   (%keys :accessor keys :initarg :keys)
   (%combining-type :accessor combining-type :initarg :combining-type :initform :or)
   (%rules :accessor rules :initform '())
   (%items :reader items :initarg :items)
   (%return-value :accessor return-value :initform :cancelled))
  (:menu-bar nil)
  (:panes
   (rule-list :application
              :display-time :command-loop
              :display-function 'display-rule-list)
   (add-rule :push-button
             :label "Add new rule"
             :activate-callback (lambda (gadget)
                                  (declare (ignore gadget))
                                  (let ((rule (make-instance 'rule)))
                                    (setf (rules *application-frame*)
                                          (append (rules *application-frame*) (list rule)))
                                    (redisplay-frame-panes *application-frame*))))
   (ok :push-button
       :label "OK"
       :activate-callback (lambda (gadget)
                            (declare (ignore gadget))
                            (setf (return-value *application-frame*)
                                  (apply-filter *application-frame*))
                            (frame-exit *application-frame*)))
   (cancel :push-button
           :label "Cancel"
           :activate-callback (lambda (gadget)
                                (declare (ignore gadget))
                                (setf (return-value *application-frame*) :cancelled)
                                (frame-exit *application-frame*)))
   (combining-type-list :option-pane
                        :items '((:or "Match any rule")
                                 (:and "Match all rules"))
                        :name-key #'second
                        :value-key #'first
                        :value :or
                        :value-changed-callback
                        (lambda (gadget value)
                          (declare (ignore gadget))
                          (setf (combining-type *application-frame*) value))))
  (:layouts
   (default (vertically ()
              rule-list
              (horizontally () combining-type-list +fill+ add-rule ok cancel)))))

(defun display-rule-list (frame pane)
  (dolist (rule (rules frame))
    (display-rule frame pane rule)))

(defun display-rule (frame pane rule)
  (let* ((text (make-pane
                :text-editor
                :value (value rule)
                :width 400 :height 2
                :value-changed-callback
                (lambda (gadget value)
                  (declare (ignore gadget))
                  (setf (value rule) value))))
         (predicate (make-pane
                     :option-pane
                     :value (predicate rule)
                     :items (predicates frame)
                     :name-key 'pretty-name
                     :value-changed-callback 
                     (lambda (gadget value)
                       (declare (ignore gadget))
                       (setf (predicate rule) value)
                       (redisplay-frame-panes frame))))
         (key (make-pane
               :option-pane
               :value (key rule)
               :items (keys frame)
               :name-key 'pretty-name
               :value-changed-callback
               (lambda (gadget value)
                 (declare (ignore gadget))
                 (setf (key rule) value)))))
    (surrounding-output-with-border (pane :shape :rounded)
      (format pane "Predicate~%")
      (with-output-as-gadget (pane)
        predicate)
      (format pane "~%on key~%")
      (with-output-as-gadget (pane)
        key)
      (terpri pane)
      (when (= (arguments (predicate rule)) 2)
        (format pane "with value~%")
        (surrounding-output-with-border (pane)
          (with-output-as-gadget (pane)
            text))
        (terpri pane))
      (with-output-as-gadget (pane)
        (make-pane :push-button
                   :label "Delete rule"
                   :activate-callback
                   (lambda (gadget)
                     (declare (ignore gadget))
                     (setf (rules frame) (delete rule (rules frame)))
                     (redisplay-frame-panes frame)))))
    (terpri pane)))

(defmethod apply-filter ((frame filter-maker))
  (flet ((filter (item)
           (cond
             ((eq :or (combining-type frame))
              (loop :for rule :in (rules frame)
                    :when (apply-rule rule item)
                      :return t
                    :finally (return nil)))
             ((eq :and (combining-type frame))
              (loop :for rule :in (rules frame)
                    :when (not (apply-rule rule item))
                      :return nil
                    :finally (return t))))))
    (if (null (rules frame))
        nil ; An empty filter matches on nothing.
        (loop :for item :in (items frame)
              :when (filter item)
                :collect item))))

(defun run-filter-maker (items predicates keys)
  (let ((frame (make-application-frame 'filter-maker
                                       :predicates predicates
                                       :keys keys
                                       :items items)))
    (run-frame-top-level frame)
    (values (return-value frame) (rules frame))))

(defun filter (predicates keys items)
  "Display a GUI filter maker with PREDICATES and KEYS that will filter ITEMS."
  (run-filter-maker
   items
   (loop :for predicate-def :in predicates
         :collect (make-instance 'predicate
                                  :function (first predicate-def)
                                  :pretty-name (second predicate-def)
                                  :arguments (third predicate-def)))
    (loop :for key-def :in keys
          :collect (make-instance 'key
                                   :function (first key-def)
                                   :pretty-name (second key-def)))))
