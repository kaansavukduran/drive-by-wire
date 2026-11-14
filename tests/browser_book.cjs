// The linear campaign uses one shared real-input acceptance flow.
process.env.DBW_INPUT=process.env.DBW_INPUT||'keyboard';
require('./browser_linear.cjs');
