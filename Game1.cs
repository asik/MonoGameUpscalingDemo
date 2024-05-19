using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace UpscalingInMonoGame;

enum ScalingMode
{
    Bilinear,
    Lanczos,
    FsrEasuOnly,
    Fsr
}

// Press number keys 1 to 4 to select the scaling mode.

public class Game1 : Game
{
    GraphicsDeviceManager _graphics;
    SpriteBatch _spriteBatch;
    Texture2D _inputTexture;
    Effect _lanczosEffect;
    Effect _fsrEasuEffect;
    Effect _fsrRcasEffect;
    RenderTarget2D _outputTarget;
    Point _outputSize = new Point(1600, 1200);
    KeyboardState _previousState;
    ScalingMode _mode = ScalingMode.Bilinear;

    public Game1()
    {
        _graphics = new GraphicsDeviceManager(this)
        {
            GraphicsProfile = GraphicsProfile.HiDef,
            PreferredBackBufferWidth = 1600,
            PreferredBackBufferHeight = 1200
        };
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        // TODO: Add your initialization logic here

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        // Load the texture
        _inputTexture = Content.Load<Texture2D>("Source");

        _outputTarget = new RenderTarget2D(GraphicsDevice, _outputSize.X, _outputSize.Y);

        // Load the shader
        _lanczosEffect = Content.Load<Effect>("Lanczos");
        // Set the constant buffer values
        _lanczosEffect.Parameters["inputWidth"].SetValue((float)_inputTexture.Width);
        _lanczosEffect.Parameters["inputHeight"].SetValue((float)_inputTexture.Height);
        _lanczosEffect.Parameters["inputPtX"].SetValue(1.0f / _inputTexture.Width);
        _lanczosEffect.Parameters["inputPtY"].SetValue(1.0f / _inputTexture.Height);

        _fsrEasuEffect = Content.Load<Effect>("FSR_EASU");
        _fsrEasuEffect.Parameters["inputWidth"].SetValue((float)_inputTexture.Width);
        _fsrEasuEffect.Parameters["inputHeight"].SetValue((float)_inputTexture.Height);
        _fsrEasuEffect.Parameters["inputPtX"].SetValue(1.0f / _inputTexture.Width);
        _fsrEasuEffect.Parameters["inputPtY"].SetValue(1.0f / _inputTexture.Height);
        _fsrEasuEffect.Parameters["outputSizeX"].SetValue(_outputSize.X);
        _fsrEasuEffect.Parameters["outputSizeY"].SetValue(_outputSize.Y);

        _fsrRcasEffect = Content.Load<Effect>("FSR_RCAS");

        // Create a render target for the upscaled output
        //_renderTarget = new RenderTarget2D(GraphicsDevice, 1600, 1200);
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || 
            Keyboard.GetState().IsKeyDown(Keys.Escape))
            Exit();

        // TODO: Add your update logic here
        var newKS = Keyboard.GetState();
        bool IsKeyPressed(Keys key) =>
            newKS.IsKeyDown(key) && !_previousState.IsKeyDown(key);

        var modeKeys = new[] { 1, 2, 3, 4 };
        foreach(var key in modeKeys)
        {
            if (IsKeyPressed(Keys.D0 + key))
            {
                _mode = (ScalingMode)(key - 1);
            }
        }

        _previousState = newKS;
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.SetRenderTarget(_outputTarget);
        GraphicsDevice.Clear(Color.Purple);

        switch(_mode)
        {
            case ScalingMode.Bilinear:
                {
                    _spriteBatch.Begin();
                    break;
                }
            case ScalingMode.Lanczos:
                {
                    _spriteBatch.Begin(effect: _lanczosEffect);
                    break;
                }
            case ScalingMode.FsrEasuOnly:
            case ScalingMode.Fsr:
                {
                    _spriteBatch.Begin(samplerState: SamplerState.PointClamp, effect: _fsrEasuEffect);
                    break;
                }
        }
        _spriteBatch.Draw(_inputTexture, new Rectangle(0, 0, 1600, 1200), Color.White);
        _spriteBatch.End();

        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.CornflowerBlue);

        switch(_mode)
        {
            case ScalingMode.Fsr:
                {
                    _fsrRcasEffect.Parameters["inputWidth"].SetValue((float)_outputTarget.Width);
                    _fsrRcasEffect.Parameters["inputHeight"].SetValue((float)_outputTarget.Height);
                    _spriteBatch.Begin(samplerState: SamplerState.PointClamp, effect: _fsrRcasEffect);
                    break;
                }
            default:
                {
                    _spriteBatch.Begin();
                    break;
                }
        }

        _spriteBatch.Draw(_outputTarget, Vector2.Zero, Color.White);
        _spriteBatch.End();

        base.Draw(gameTime);
    }
}
