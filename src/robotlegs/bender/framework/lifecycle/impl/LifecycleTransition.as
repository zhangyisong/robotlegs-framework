//------------------------------------------------------------------------------
//  Copyright (c) 2011 the original author or authors. All Rights Reserved. 
// 
//  NOTICE: You are permitted to use, modify, and distribute this file 
//  in accordance with the terms of the license agreement accompanying it. 
//------------------------------------------------------------------------------

package robotlegs.bender.framework.lifecycle.impl
{
	import robotlegs.bender.core.async.safelyCallBack;
	import robotlegs.bender.core.messaging.MessageDispatcher;
	import robotlegs.bender.framework.lifecycle.api.LifecycleEvent;

	public class LifecycleTransition
	{

		/*============================================================================*/
		/* Private Properties                                                         */
		/*============================================================================*/

		private const _fromStates:Vector.<String> = new Vector.<String>;

		private const _dispatcher:MessageDispatcher = new MessageDispatcher();

		private const _callbacks:Array = [];

		private var _name:String;

		private var _lifecycle:Lifecycle;

		private var _transitionState:String;

		private var _finalState:String;

		private var _preTransitionEvent:String;

		private var _transitionEvent:String;

		private var _postTransitionEvent:String;

		private var _reverse:Boolean;

		private var _locked:Boolean;

		/*============================================================================*/
		/* Constructor                                                                */
		/*============================================================================*/

		public function LifecycleTransition(name:String, lifecycle:Lifecycle)
		{
			_name = name;
			_lifecycle = lifecycle;
		}

		/*============================================================================*/
		/* Public Functions                                                           */
		/*============================================================================*/

		public function fromStates(... states):LifecycleTransition
		{
			validateLock();
			for each (var state:String in states)
				_fromStates.push(state);
			return this;
		}

		public function toStates(transitionState:String, finalState:String):LifecycleTransition
		{
			validateLock();
			_transitionState = transitionState;
			_finalState = finalState;
			return this;
		}

		public function withEvents(preTransitionEvent:String, transitionEvent:String, postTransitionEvent:String):LifecycleTransition
		{
			validateLock();
			_preTransitionEvent = preTransitionEvent;
			_transitionEvent = transitionEvent;
			_postTransitionEvent = postTransitionEvent;
			_reverse && _lifecycle.addReversedEventTypes(preTransitionEvent, transitionEvent, postTransitionEvent);
			return this;
		}

		public function inReverse():LifecycleTransition
		{
			validateLock();
			_reverse = true;
			_lifecycle.addReversedEventTypes(_preTransitionEvent, _transitionEvent, _postTransitionEvent);
			return this;
		}

		public function withBeforeHandlers(... handlers):LifecycleTransition
		{
			for each (var handler:Function in handlers)
				_dispatcher.addMessageHandler(_name, handler);
			return this;
		}

		public function enter(callback:Function = null):void
		{
			// no more configuration beyond this point
			_locked = true;

			// immediately call back if we have already transitioned, and exit
			if (_lifecycle.state == _finalState)
			{
				callback && safelyCallBack(callback, null, _name);
				return;
			}

			// queue this callback if we are mid transition, and exit
			if (_lifecycle.state == _transitionState)
			{
				callback && _callbacks.push(callback);
				return;
			}

			// report invalid transition, and exit
			if (invalidTransition())
			{
				reportError("Invalid transition", [callback]);
				return;
			}

			// store the initial lifecycle state in case we need to roll back
			const initialState:String = _lifecycle.state;

			// queue the first callback
			callback && _callbacks.push(callback);

			// put lifecycle into transition state
			setState(_transitionState);

			// run before handlers
			_dispatcher.dispatchMessage(_name, function(error:Object):void
			{
				// revert state, report error, and exit
				if (error)
				{
					setState(initialState);
					reportError(error, _callbacks);
					return;
				}

				// dispatch pre transition and transition events
				dispatch(_preTransitionEvent);
				dispatch(_transitionEvent);

				// put lifecycle into final state
				setState(_finalState);

				// dispatch post transition event
				dispatch(_postTransitionEvent);

				// process callback queue
				for each (var callback:Function in _callbacks)
					safelyCallBack(callback, null, _name);
				_callbacks.length = 0;

			}, _reverse ? MessageDispatcher.REVERSE : 0); // todo: remove this FLAG nonsense
		}

		/*============================================================================*/
		/* Private Functions                                                          */
		/*============================================================================*/

		private function validateLock():void
		{
			_locked && reportError("State is locked");
		}

		private function invalidTransition():Boolean
		{
			return _fromStates.length > 0
				&& _fromStates.indexOf(_lifecycle.state) == -1;
		}

		private function setState(state:String):void
		{
			state && _lifecycle.setCurrentState(state);
		}

		private function dispatch(type:String):void
		{
			if (type && _lifecycle.hasEventListener(type))
				_lifecycle.dispatchEvent(new LifecycleEvent(type));
		}

		private function reportError(message:Object, callbacks:Array = null):void
		{
			// turn message into Error
			const error:Error = message is Error
				? message as Error
				: new Error(message);

			// dispatch error event if a listener exists, or throw
			if (_lifecycle.hasEventListener(LifecycleEvent.ERROR))
			{
				const event:LifecycleEvent = new LifecycleEvent(LifecycleEvent.ERROR);
				event.error = error;
				_lifecycle.dispatchEvent(event);
				// process callback queue
				if (callbacks)
				{
					for each (var callback:Function in callbacks)
						callback && safelyCallBack(callback, error, _name);
					callbacks.length = 0;
				}
			}
			else
			{
				// explode!
				throw(error);
			}
		}
	}
}