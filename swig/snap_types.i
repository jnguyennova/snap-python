// snap_types.i
//
// Provides an interface between Python types (lists, strings) and SNAP.
//
%typemap(in) (char *str, int len) {
  $1 = PyString_AsString($input);   /* char *str */
  $2 = PyString_Size($input);       /* int len   */
}

// Create type for fixed-size Python lists of doubles.
%typemap(in) double [ANY] (double temp[$1_dim0]) {
  int i;
  if (!PySequence_Check($input)) {
    PyErr_SetString(PyExc_ValueError,"Expected a sequence");
    return NULL;
  }
  if (PySequence_Length($input) != $1_dim0) {
    PyErr_SetString(PyExc_ValueError,"Size mismatch. Expected $1_dim0 elements");
    return NULL;
  }
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PySequence_GetItem($input,i);
    if (PyNumber_Check(o)) {
      temp[i] = (double) PyFloat_AsDouble(o);
    } else {
      PyErr_SetString(PyExc_ValueError,"Sequence elements must be numbers");
      return NULL;
    }
  }
  $1 = temp;
}

// Create type for Python fixed-size lists of integers.
%typemap(in) int[ANY] (int temp[$1_dim0]) {
  int i;
  if (!PySequence_Check($input)) {
    PyErr_SetString(PyExc_ValueError,"Expected a sequence");
    return NULL;
  }
  if (PySequence_Length($input) != $1_dim0) {
    PyErr_SetString(PyExc_ValueError,"Size mismatch. Expected $1_dim0 elements");
    return NULL;
  }
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PySequence_GetItem($input,i);
    if (PyNumber_Check(o)) {
      temp[i] = (int) PyInt_AsLong(o);
    } else {
      PyErr_SetString(PyExc_ValueError,"Sequence elements must be numbers");
      return NULL;
    }
  }
  $1 = temp;
}

// Translate Python strings to SNAP TStr
//%typemap(in) const TStr& attr {
//  TStr S(PyString_AsString($input));
//  $1 = &S;
//}

// Translate Python strings to SNAP TStr
%typemap(in) const TStr& {
  $1 = new TStr(PyString_AsString($input));
}

%typemap(in) TStr defaultValue {
  TStr S(PyString_AsString($input));
  $1 = S;
}

// Translate Python ints to TInt
%typemap(in) const TInt& {
//%typemap(in) const TInt& value {
  //TInt I = PyInt_AsLong($input);
  //$1 = &I;
  $1 = new TInt(PyInt_AsLong($input));
}

%typemap(in) TInt defaultValue {
  TInt I = PyInt_AsLong($input);
  $1 = I;
}

%typemap(in) TInt& {
//%typemap(in) TInt & NId {
  //TInt I = PyInt_AsLong($input);
  //$1 = &I;
  $1 = new TInt(PyInt_AsLong($input));
}

// Translate Python floats to TInt
%typemap(in) const TFlt &value {
  TFlt F = PyFloat_AsDouble($input);
  $1 = &F;
}

%typemap(in) TFlt defaultValue {
  TFlt F = PyFloat_AsDouble($input);
  $1 = F;
}

// Slow but safe.  Create type for Python variable-size lists of integers (must keep argument name or create typemap.
%typemap(in) (int *arraySlow, int lengthSlow) {
  int i;
  if (!PySequence_Check($input)) {
    PyErr_SetString(PyExc_ValueError,"Expected a sequence");
    return NULL;
  }
  int lengthSlow = PySequence_Size($input);
  int *temp = (int *) malloc(lengthSlow*sizeof(int));
  for (i = 0; i < lengthSlow; i++) {
    PyObject *o = PySequence_GetItem($input,i);
    if (PyNumber_Check(o)) {
      temp[i] = (int) PyInt_AsLong(o);
    } else {
      PyErr_SetString(PyExc_ValueError,"Sequence elements must be numbers");
      return NULL;
    }
  }
  $1 = temp;
  $2 = lengthSlow;
}

// Fast.  Create type for Python variable-size lists of integers (must keep argument name or create typemap.
%typemap(in) (int *array, int length) {
  int i;
  PyObject* seq = PySequence_Fast($input, "expected a sequence");
  int length = PySequence_Size($input);
  int *temp = (int *) malloc(length*sizeof(int));
  for (i = 0; i < length; i++) {
    temp[i] = (int) PyInt_AsLong(PySequence_Fast_GET_ITEM(seq, i));
  }
  Py_DECREF(seq);
  $1 = temp;
  $2 = length;
}
%typemap(freearg) (int *array, int length) {
     if ($1) free($1);
}

// Convert an TIntV to a Python list

%module outarg

%typemap(argout) TIntV *OutValue {
  $result = PyList_New($1->Len());
  for (int i = 0; i < $1->Len(); ++i) {
    PyList_SetItem($result, i, PyInt_FromLong((*$1)[i]));
  }
  delete $1; // Avoid a leak since you called new
}

%typemap(in,numinputs=0) TIntV *OutValue(TIntV temp) {
    $1 = &temp;
}


// Rename argument example.
%typemap(in) (char *buffer, int size) = (char *str, int len);

%include "snap_types.h"

